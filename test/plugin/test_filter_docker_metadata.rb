require_relative '../helper'
require 'fluent/plugin/filter_docker_metadata'

require 'webmock/test_unit'
WebMock.disable_net_connect!

class DockerMetadataFilterTest < Test::Unit::TestCase
  include Fluent

  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
  end

  def create_driver(conf = '')
    Test::FilterTestDriver.new(DockerMetadataFilter).configure(conf, true)
  end

  sub_test_case 'configure' do
    test 'check default' do
      d = create_driver
      assert_equal(d.instance.docker_url, 'unix:///var/run/docker.sock')
      assert_equal(100, d.instance.cache_size)
    end

    test 'docker url' do
      d = create_driver(%[docker_url http://docker-url])
      assert_equal('http://docker-url', d.instance.docker_url)
      assert_equal(100, d.instance.cache_size)
    end

    test 'keys_delimiter' do
      d = create_driver(%[docker_url http://docker-url])
      assert_equal(',', d.instance.keys_delimiter)
      assert_equal(100, d.instance.cache_size)
    end

    test 'values_delimiter' do
      d = create_driver(%[docker_url http://docker-url])
      assert_equal(':', d.instance.values_delimiter)
      assert_equal(100, d.instance.cache_size)
    end

    test 'image_name' do
      d = create_driver(%[docker_url http://docker-url])
      assert_equal(false, d.instance.image_name)
      assert_equal(100, d.instance.cache_size)
    end

    test 'image_id' do
      d = create_driver(%[docker_url http://docker-url])
      assert_equal(false, d.instance.image_id)
      assert_equal(100, d.instance.cache_size)
    end

    test 'labels' do
      d = create_driver(%[docker_url http://docker-url])
      assert_equal('', d.instance.labels)
      assert_equal(100, d.instance.cache_size)
    end

    test 'cache size' do
      d = create_driver(%[cache_size 1])
      assert_equal('unix:///var/run/docker.sock', d.instance.docker_url)
      assert_equal(1, d.instance.cache_size)
    end
  end

  sub_test_case 'filter_stream' do
    def messages
      [
        "2013/01/13T07:02:11.124202 INFO GET /ping",
        "2013/01/13T07:02:13.232645 WARN POST /auth",
        "2013/01/13T07:02:21.542145 WARN GET /favicon.ico",
        "2013/01/13T07:02:43.632145 WARN POST /login",
      ]
    end

    def emit(config, msgs, tag='2dc9528d182cef01f03ccb69bc0d51c2d44ee7c8655d165d5f15507de766bb5e')
      d = create_driver(config)
      d.run {
        msgs.each { |msg|
          d.emit_with_tag(tag, {'foo' => 'bar', 'message' => msg}, @time)
        }
      }.filtered
    end

    test 'docker metadata with default configs' do
      VCR.use_cassette('fastlane_container') do
        es = emit('', messages)
        assert_equal(4, es.instance_variable_get(:@record_array).size)
        assert_equal('2dc9528d182cef01f03ccb69bc0d51c2d44ee7c8655d165d5f15507de766bb5e', es.instance_variable_get(:@record_array)[0]['container_id'])
        assert_equal('fastlane_community_frontend_web.1.k6j8nk6qbaeo7609gz31axszw', es.instance_variable_get(:@record_array)[0]['container_name'])
        assert_equal('2dc9528d182c', es.instance_variable_get(:@record_array)[0]['container_hostname'])
        assert_nil(es.instance_variable_get(:@record_array)[0]['image_id'])
        assert_nil(es.instance_variable_get(:@record_array)[0]['container_image'])
      end
    end

    test 'docker metadata with enable image id and name' do
      VCR.use_cassette('fastlane_container') do
        config =  %[
          image_id true
          image_name true
        ]
        es = emit(config, messages)
        assert_equal(4, es.instance_variable_get(:@record_array).size)
        assert_equal('2dc9528d182cef01f03ccb69bc0d51c2d44ee7c8655d165d5f15507de766bb5e', es.instance_variable_get(:@record_array)[0]['container_id'])
        assert_equal('fastlane_community_frontend_web.1.k6j8nk6qbaeo7609gz31axszw', es.instance_variable_get(:@record_array)[0]['container_name'])
        assert_equal('2dc9528d182c', es.instance_variable_get(:@record_array)[0]['container_hostname'])
        assert_equal('sha256:eab04071e2f0fdf80a6c4b8d88de1cf9424818a6a1eec304ba8082c162fff557', es.instance_variable_get(:@record_array)[0]['image_id'])
        assert_equal('docker-prod.me/fastlane/auth_service:latest', es.instance_variable_get(:@record_array)[0]['container_image'])
      end
    end

    test 'docker metadata with existing lables' do
      VCR.use_cassette('fastlane_container') do
        config =  %[
          labels com.docker.stack.namespace:namespace,com.docker.swarm.service.id:service_id,com.docker.swarm.service.name:service_image
        ]
        es = emit(config, messages)
        assert_equal(4, es.instance_variable_get(:@record_array).size)
        assert_equal('fastlane', es.instance_variable_get(:@record_array)[0]['namespace'])
        assert_equal('fastlane_community_frontend_web', es.instance_variable_get(:@record_array)[0]['service_image'])
        assert_equal('5nkbd9f8oqoumdry4e0nqj33k', es.instance_variable_get(:@record_array)[0]['service_id'])
      end
    end


    test 'docker metadata with nonexistent lables' do
      VCR.use_cassette('fastlane_container') do
        config =  %[
          labels com.docker.stack.namespace:namespace,com.swarm.service.none:undefined
        ]
        es = emit(config, messages)
        assert_equal(4, es.instance_variable_get(:@record_array).size)
        assert_equal('fastlane', es.instance_variable_get(:@record_array)[0]['namespace'])
        assert_nil(es.instance_variable_get(:@record_array)[0]['undefined'])
        assert_nil(es.instance_variable_get(:@record_array)[0]['unconfigerd'])
      end
    end

    test 'nonexistent docker metadata' do
      VCR.use_cassette('invalid') do
        es = emit('', messages, '0001119991111111111111111100011111111111111111111111111111111111')
        assert_equal(4, es.instance_variable_get(:@record_array).size)
        assert_nil(es.instance_variable_get(:@record_array)[0]['container_id'])
        assert_nil(es.instance_variable_get(:@record_array)[0]['container_name'])
        assert_nil(es.instance_variable_get(:@record_array)[0]['container_hostname'])
      end
    end
  end
end
