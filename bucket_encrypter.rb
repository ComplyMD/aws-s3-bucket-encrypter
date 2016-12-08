#!/usr/bin/env ruby
#
# Script to encrypt the contents of an entire S3 bucket
#
# This works by copying each object in the bucket onto
# itself while modifying its server_side_encryption attribute
#
#
##############################################################

require 'aws-sdk'
require 'optparse'

def parse_options
  options = {}
  opt_parse = OptionParser.new do |opts|
    opts.banner = "Usage: bucket_encrypter.rb [options]"
    opts.on('-b', '--bucket NAME', 'REQUIRED - Name of the bucket to encrypt the contents of') { |v| options[:bucket] = v }
    opts.on('-r', '--region NAME', 'REQUIRED - Region in which the bucket to be encrypted is located') { |v| options[:region] = v }
    opts.on('-k', '--access-key KEY', 'Access Key ID AWS credential') { |v| options[:access_key_id] = v }
    opts.on('-s', '--secret-access-key KEY', 'Secret Access Key AWS credential') { |v| options[:secret_access_key] = v }
    opts.on('-n', '--batch-size NUMBER', 'Size of batches to retrieve from bucket. Defaults to 100') { |v| options[:batch_size] = v }
    opts.on('-c', '--cipher NAME', 'Method with which the objects will encrypted. Accepts aws:kms or AES256. Defaults to AES256') { |v| options[:cipher] = v }
    opts.on('-v', '--verbose', 'Output more information. Useful for debugging or if you want to be sure things are actually working') { |v| options[:verbose] = true }
  end

  opt_parse.parse!

  options[:batch_size] = 100 if options[:batch_size].nil?
  options[:cipher] = "AES256" if options[:cipher].nil?
  if options[:bucket].nil? || options[:region].nil?
    puts opt_parse
    exit 1
  end
  options
end

class BucketEncrypter
  def initialize(opts)
    sdk_client_option_keys = %w( access_key_id secret_access_key region ).map(&:to_sym)
    sdk_client_options = Hash[sdk_client_option_keys.map {|k| [k, opts[k]] unless opts[k].nil? }.compact]
    @s3_client = Aws::S3::Client.new(sdk_client_options)
    @batch_size = opts[:batch_size]
    @cipher = opts[:cipher]
    @bucket_name = opts[:bucket]
    @verbose_output = !!opts[:verbose]
  end

  def bucket_objects
    @bucket_objects ||= fetch_objects # only fetch the results the first time
  end

  def encrypt_all_objects
    bucket_objects.each_with_index do |s3_object, i|
      @s3_client.copy_object({
        bucket: @bucket_name,
        key: s3_object.key,
        copy_source: "#{@bucket_name}/#{s3_object.key}",
        server_side_encryption: @cipher
      })
      puts "Encrypted #{i+1} of #{bucket_objects.count} (#{s3_object.key})" if @verbose_output
    end
  end

  private

  def fetch_objects
    objects = []
    continuation_token = nil
    i = 0
    begin
      resp = @s3_client.list_objects_v2(bucket: @bucket_name, continuation_token: continuation_token, max_keys: @batch_size)
      continuation_token = resp.next_continuation_token
      objects.push(*resp.contents)
      puts "Retrieved objects #{i*@batch_size} - #{(i+1)*@batch_size} from #{@bucket_name}" if @verbose_output
      i+=1
    end while !continuation_token.nil?

    objects
  end
end

BucketEncrypter.new(parse_options).encrypt_all_objects
