from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import numpy as np

compile_args = ['-g', '-std=c++11']
extensions = [
    Extension("*", ["**/*.pyx"],
        include_dirs=[np.get_include(), "."],
        extra_compile_args=compile_args,
        language="c++")
]

setup(
    name='Jike',
    version='0.1',
    ext_modules=cythonize(extensions),
)
