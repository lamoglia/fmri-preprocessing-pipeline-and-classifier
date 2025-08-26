# this script reads metadata from nifti file headers
import numpy as np
np.set_printoptions(precision=4, suppress=True)
import nibabel as nib
import sys
import argparse
import sys

parser = argparse.ArgumentParser(description='Extracts info from nifti file headers.')
parser.add_argument('filename') # positional argument
parser.add_argument('--tr', action='store_true')
parser.add_argument('--pixel', action='store_true')
parser.add_argument('--length', action='store_true')
parser.add_argument('--size', action='store_true')

args = parser.parse_args()

path = args.filename

func_img = nib.load(path)
header = func_img.header
pixdim = header.get_zooms()
shape = header.get_data_shape()


if args.tr:
  print("{} {}".format(pixdim[3], header.get_xyzt_units()[1]))

if args.pixel:
  print("{} x {} x {} {}".format(pixdim[0], pixdim[1], pixdim[2], header.get_xyzt_units()[0]))

if args.length:
  print("{}".format(shape[3]))

if args.size:
  print("{} x {} x {}".format(shape[0], shape[1], shape[2]))

if args.tr or args.pixel or args.length or args.size:
  sys.exit(0)

print("Tr {} {}".format(pixdim[3], header.get_xyzt_units()[1]))
print("Size {} x {} x {} {}".format(pixdim[0], pixdim[1], pixdim[2], header.get_xyzt_units()[0]))