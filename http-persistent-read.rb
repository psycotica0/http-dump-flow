#!/usr/bin/ruby

require 'fileutils'
require 'zlib'
require 'stringio'

if ARGV.size != 2
	raise "Must give two arguments. Filename of request file and response file."
end

class String
	def dump_to_file(filename)
		FileUtils.mkdir_p File.dirname(filename)
		open(filename, "w") do |dump_file|
			dump_file.write(self)
		end
	end
	def unzip
		begin
			reader = Zlib::GzipReader.new(StringIO.new(self))
			value = reader.read
			reader.close
		rescue
			STDERR.puts "Failed to unzip string."
			value = self
		end
		value
	end
end

# This does a setup, a body if the condition is true, then a breakdown every iteration until after the first where the condition is true
def three_part_loop(setup, breakdown, condition, body)
	done = false
	until done
		setup.call
		done = condition.call
		body.call unless done
		breakdown.call
	end
end

request_stream = File.open(ARGV[0])
response_stream = File.open(ARGV[1])

until request_stream.eof? do
	request = request_stream.readline("\r\n\r\n")
	host = request[/Host:(.*)\r\n/i,1].strip
	path = request.split("\r\n")[0][/\/[a-zA-Z0-9.%_\/!~*'()+-]*/]

	request_size = request[/Content-Length: *([0-9]*)/i,1]
	request += request_stream.read(request_size.to_i) unless request_size.nil?

	index = Dir.glob(host+path+".request.*").map do |i|
		i.reverse[/[0-9]*/].reverse.to_i
	end.max

	if index == nil
		index = 0
	else
		index += 1
	end

	request.dump_to_file(host+path+".request."+index.to_s)

	response_headers = response_stream.readline("\r\n\r\n")
	response_size = response_headers[/Content-Length: *([0-9]*)/i,1]
	response_body = ""
	if !(response_size.nil?)
		response_body = response_stream.read(response_size.to_i)
	elsif !(response_headers.match(/Transfer-Encoding: *chunked/i).nil?)
		size = 0
		# Read every chunk until one is 0, consuming a newline after every chunk including last empty one
		three_part_loop(lambda {size = response_stream.readline("\r\n").to_i(16)}, lambda {response_stream.read(2)},
		                lambda {size == 0}, lambda {response_body += response_stream.read(size)})
	end
	response_headers.dump_to_file(host+path+".headers."+index.to_s)
	response_body = response_body.unzip unless (response_body=='' || response_headers[/Content-Encoding: *gzip/i].nil?)
	response_body.dump_to_file(host+path+"."+index.to_s) unless response_body==""
end

request_stream.close
response_stream.close
