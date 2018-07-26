module Fluent
  class DockerMetadataFilter < Fluent::Filter
    Fluent::Plugin.register_filter('docker_metadata', self)

    config_param :docker_url, :string,  default: 'unix:///var/run/docker.sock'
    config_param :cache_size, :integer, default: 100
    config_param :container_id_regexp, :string, default: '(\w{64})'
    config_param :keys_delimiter, :string, default: ','
    config_param :values_delimiter, :string, default: ':'
    config_param :image_name, :bool, default: false
    config_param :image_id, :bool, default: false
    config_param :labels, :string, default: ''

    def self.get_metadata(container_id)
      begin
        Docker::Container.get(container_id).info
      rescue Docker::Error::NotFoundError
        nil
      end
    end

    def initialize
      super
    end

    def configure(conf)
      super

      require 'docker'
      require 'json'
      require 'lru_redux'

      Docker.url = @docker_url

      @cache = LruRedux::ThreadSafeCache.new(@cache_size)
      @container_id_regexp_compiled = Regexp.compile(@container_id_regexp)
    end

    def filter_stream(tag, es)
      new_es = es
      container_id = tag.match(@container_id_regexp_compiled)
      if container_id && container_id[0]
        container_id = container_id[0]
        metadata = @cache.getset(container_id){DockerMetadataFilter.get_metadata(container_id)}

        if metadata
          new_es = MultiEventStream.new

          es.each {|time, record|
            record.merge!({
              'container_id' => metadata['id'],
              'container_name' => metadata['Name'][1..-1],
              'container_hostname' => metadata['Config']['Hostname']
            })

            record.merge!({'container_image' => metadata['Config']['Image'] }) if @image_name
            record.merge!({'image_id' => metadata['Image']}) if @image_id

            @labels.split(@keys_delimiter).each do |pattern_name|
              lable, caption = pattern_name.split(@values_delimiter)
              raise ConfigError, "label caption is needed" if caption.nil?
              record.merge!({"#{caption}" => metadata['Config']['Labels'][lable].to_s}) unless metadata['Config']['Labels'][lable].nil?
            end
            new_es.add(time, record)
          }
        end
      end

      return new_es
    end
  end

end
