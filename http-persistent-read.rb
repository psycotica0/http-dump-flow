#!/usr/bin/ruby

if ARGV.size != 2
	raise "Must give two arguments. Filename of request file and response file."
end

class String
	def dump_to_file(filename)
		pwd = Dir.pwd
		dirs = File.dirname(filename).split('/')
		dirs.each do |dir|
			if !(File.directory?(dir))
				Dir.mkdir(dir)
			end
			Dir.chdir(dir)
		end
		Dir.chdir(pwd)
		File.open(filename, "w") do |dump_file|
			dump_file.write(self)
		end
	end
end

request_stream = File.open(ARGV[0])
response_stream = File.open(ARGV[1])

requests = request_stream.read.split("\r\n\r\n")

requests.each do |request|
	host = request[/Host:(.*)\r\n/,1].strip
	path = request.split("\r\n")[0][/\/[a-zA-Z0-9.%_\/-]*/]

	index=0
	while File.exists?(host+path+".request."+index.to_s)
		index = index.succ
	end
	request.dump_to_file(host+path+".request."+index.to_s)

	response_headers = response_stream.readline("\r\n\r\n")
	response_size = response_headers[/Content-Length: *([0-9]*)/,1]
	response_body = ""
	if response_size != nil
		response_body = response_stream.read(response_size.to_i)
	else
		if response_headers.match(/Transfer-Encoding: *chunked/) == nil
			raise "Neither content length nor chunked"
		end
		while true
			size = response_stream.readline("\r\n").to_i(16)
			if size == 0
				break
			end
			response_body = response_body + response_stream.read(size)
			# Consume newline
			response_stream.read(2)
		end
		# Consume last newline
		response_stream.read(2)
	end
	response_headers.dump_to_file(host+path+".headers."+index.to_s)
	response_body.dump_to_file(host+path+"."+index.to_s)
end

request_stream.close
response_stream.close
