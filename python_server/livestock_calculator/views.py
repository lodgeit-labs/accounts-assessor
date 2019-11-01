probably to be deleted.

from django.http import HttpResponse
from django.shortcuts import render

def livestock_response_html():
	solutions = solve_livestock()
	return "<html><body>\n" + response_body(solutions).replace('\n', '<br>\n') + "\n</body></html>"


if __name__ == '__main__':
	print(livestock_response_html())


def index(request):
	return HttpResponse(livestock_response_html())

