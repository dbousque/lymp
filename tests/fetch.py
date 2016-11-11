

class Fetch:
	def __init__(self, url, mode):
		self.url = url
		self.mode = mode

	def download(self):
		if self.mode == "phantom":
			return "<html><p>Hi from phantom</p></html>"
		return "<html><p>Hi</p></html>"

	def ret_self(self):
		return self

	def ret_list(self):
		return [1,2,self, ["salut", 3], 4]

	def ret_list2(self):
		return [1, 2]