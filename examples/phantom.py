

import lxml.html as lx
from selenium import webdriver

driver = webdriver.PhantomJS()
driver.set_window_size(1024, 768)

def download(url):
	driver.get(url)
	driver.save_screenshot('screen.png')
	return driver.page_source

def select(html, css_selector):
	doc = lx.fromstring(html)
	return doc.cssselect(css_selector)