infile = 'M7Test.smc'

def calc_sum(body)
	w = 0
	body.each{|b| w = (w+b) & 0xFFFF }
	return w
end

def as_word(arr, pos)
	arr[pos] | (arr[pos+1] << 8)
end

def write_word(arr, pos, val)
	arr[pos]   =  val       & 0x00ff
	arr[pos+1] = (val >> 8) & 0x00ff
end

def rewrite_checksum(body, newval)
	addr1 = 0x7FDE
	addr2 = 0x7FDC

	old1 = as_word(body, addr1)
	old2 = as_word(body, addr2)
	raise "bad" if (old1 + old2) != 0xffff

	write_word(body, addr1, newval)
	write_word(body, addr2, ~newval)
end

File.open(infile, 'rb') {|f|
	body = f.read.unpack('C*')
	sum = calc_sum(body)
	rewrite_checksum(body, sum)

	outfile = infile.sub('.smc', '-fixed.smc')
	File.open(outfile, 'wb') {|wf|
		wf.write( body.pack('C*') )
	}
}
