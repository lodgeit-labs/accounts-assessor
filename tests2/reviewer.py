#!/usr/bin/env python3
import sys,os
import time
import subprocess
import click

@click.command()
%#@click.option('--keep_putting_to_sleep', type=bool, default=False)
def main():
	with open(