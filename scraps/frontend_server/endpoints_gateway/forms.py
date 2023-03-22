from django import forms

class ClientRequestForm(forms.Form):
	file1 = forms.FileField(label='Upload files:', required=False, widget=forms.ClearableFileInput(attrs={'multiple': True}))
#required=True, but excel plugin..
