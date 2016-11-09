

class Fetch:
	def __init__(self, url, mode):
		self.url = url
		self.mode = mode

	def download(self):
		if mode == "phantom":
			return "<html><p>Hi from phantom</p></html>"
		return "<html><p>Hi</p></html>"

	def ret_self(self):
		return self