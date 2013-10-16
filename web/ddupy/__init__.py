"""
Copyright (c) 2013
Harvard FAS Research Computing
John Brunelle <john_brunelle@harvard.edu>
All right reserved.
"""

import os, re, urllib2
from lilpsp import core


RE_NONSIMPLE = re.compile(r'[^a-zA-Z0-9_\-\.]')


#--- misc

def makeSimpleText(text):
	return re.sub(RE_NONSIMPLE, '_', text)

def getUser(job):
	return job.split('/',1)[0]


#--- handlers

def img(req):
	"""serve a png image"""



	#--- BEGIN TEMPLATE CODE...
	
	try:
		from mod_python import apache, util, Session
		
		session = Session.Session(req)
		form = util.FieldStorage(req, keep_blank_values=1)
		
		req.add_common_vars()

		base_url_path = req.subprocess_env['REQUEST_URI'].split('?',1)[0]  #e.g. /PATH/FILENAME.psp, of 'https://SERVER/PATH/FILENAME.psp?FOO=BAR'
		base_url_dir = os.path.dirname(base_url_path)  #e.g. /PATH, of 'https://SERVER/PATH/FILENAME.psp?FOO=BAR'
		base_fs_dir  = os.path.dirname(req.subprocess_env['SCRIPT_FILENAME'])
		
		msg = "request from ip [%s] from user [%s]" % (req.subprocess_env['REMOTE_ADDR'], core.getUsername(session, req))
		core.log(msg, session, req)
		
		core.sessionCheck(session, req)

		#--- ...END TEMPLATE CODE



		import urllib, urllib2

		if form.has_key('job') and form.has_key('path'):
			#(these will be the un-quoted values (i.e. '/' instead of '%2F')
			path = str(form['path']).strip()
			job  = str(form['job']).strip()

			if req.is_https():
				protocol = 'https'
			else:
				protocol = 'http'

			imgurl = '%s://localhost/%s/data/%s/philesight/?cmd=img&path=%s' % (protocol, base_url_dir.lstrip('/'), job, urllib.quote(path))

			msg = 'image request for job [%s], path [%s]; serving [%s]' % (job, path, imgurl)
			core.log(msg, session, req)
			
			bytes = urllib2.urlopen(imgurl).read()
			req.headers_out.add('Content-Type', 'image/png')
			req.write(bytes)
		else:
			#FIXME
			raise Exception("internal error: handling of incomplete img query string not yet implemented")



		#--- BEGIN TEMPLATE CODE...

		return apache.OK
	except apache.SERVER_RETURN:
		##if it's re-raised, sessions start over; passing seems wrong but it's the only way I know of to make sessions persist across redirect
		#raise
		raise
	except Exception, e:
		if not ( 'core' in globals() and 'session' in locals() and 'base_url_dir' in locals() ):
			raise  #just bailout and let the server handle it (if configured with PythonDebug On, the traceback will be shown to the user)
		else:
			msg = "ERROR: exception when handling user [%s]: %s" % (core.getUsername(session, req), e)
			core.log(msg, session, req, e)
			##FIXME -- this causes server to hang
			#req.internal_redirect(os.path.join(base_url_dir,'imgfail.psp'))
			return apache.OK  #(not sure if this does anything)
	
	#--- ...END TEMPLATE CODE



if __name__=='__main__':
	p = '/this is a/test?'
	print p
	print makeSimpleText(p)
