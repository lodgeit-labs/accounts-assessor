# Generated by Django 2.2.7 on 2019-12-07 05:33

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('message', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='message',
            name='status',
            field=models.TextField(default=''),
            preserve_default=False,
        ),
    ]