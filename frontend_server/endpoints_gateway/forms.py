from django import forms

class ClientRequestForm(forms.Form):
	file1 = forms.FileField(label='Select a file', required=False)
	file2 = forms.FileField(label='Select a file', required=False)
	
