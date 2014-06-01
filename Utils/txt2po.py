import sys

def poify(filename):
	with open(filename) as f:
		lines=f.readlines()
	
	lines=filter(lambda x: len(x.strip()), lines) 
	lines=[l.replace('"','\\"') for l in lines]	
	return [
			'#: file %s\nmsgid "%s"\nmsgstr ""'%(filename,l.strip()) for l in lines]

if __name__=="__main__":
	infile=sys.argv[1]
	outfile=sys.argv[2]
	
	pl=poify(infile)
	with open(outfile,"a") as f:
		f.write("\n\n".join(pl))
		
		