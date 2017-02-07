require 'aliyun/oss'

module Backup
  module Storage
    class Aliyun < Base
      include Storage::Cycler

      attr_accessor :bucket, :area, :access_key_id, :access_key_secret, :path

      def initialize(model, storage_id = nil, &block)
        super(model, storage_id)

        @path ||= 'backups'
        @area ||= 'cn-hangzhou'

        instance_eval(&block) if block_given?
      end

      private

      def client
        return @client if defined? @client

        @client = Aliyun::OSS::Client.new(:endpoint => "oss-#{self.area}.aliyuncs.com",
                                          :access_key_id => self.access_key_id,
                                          :access_key_secret => self.access_key_secret)
        @client
      end

      def _aliyun_bucket
        client.get_bucket(self.bucket)
      end

      def transfer!
        remote_path = remote_path_for(@package)

        @package.filenames.each do |filename|
          src = File.join(Config.tmp_path, filename)
          dest = File.join(remote_path, filename)
          Logger.info "#{storage_name} uploading '#{ dest }'..."
          File.open(src, 'r') do |file|
            _aliyun_bucket.put_object(dest, :file => file)
          end
        end
      end

      def remove!(package)
        remote_path = remote_path_for(package)
        Logger.info "#{storage_name} removing '#{remote_path}'..."
        _aliyun_bucket.delete_object(remote_path)
      end
    end
  end
end
