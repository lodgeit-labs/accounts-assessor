from django import forms

class ClientRequestForm(forms.Form):
	file1 = forms.FileField(label='Upload files:', required=True, widget=forms.ClearableFileInput(attrs={'multiple': True}))
