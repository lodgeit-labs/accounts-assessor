from setuptools import setup, find_packages

setup(
    name='robust',
    version='0.1.0',
    packages=find_packages(include=['lib']),
    python_requires='>=3.9',
    install_requires=[
        'Click',
        'pyyaml'
    ],
    entry_points={
        'console_scripts': [
            'robust = lib._run:cli',
        ],
    }
)
