from django import forms

class ClientRequestForm(forms.Form):
	file1 = forms.FileField(label='Select a file', required=False)
	file2 = forms.FileField(label='Select a file', required=False)
	file3 = forms.FileField(label='Select a file', required=False)
	file4 = forms.FileField(label='Select a file', required=False)
	file5 = forms.FileField(label='Select a file', required=False)
	file6 = forms.FileField(label='Select a file', required=False)
	file7 = forms.FileField(label='Select a file', required=False)

