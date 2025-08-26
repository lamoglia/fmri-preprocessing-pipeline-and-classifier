#!/bin/bash
#re-runs top 10 experiments preprocessed with a fixed number of DIM
#running from src/

#1
./automation.sh \
    ../../data/in/top10-v3/v2_group1_dim68_fwhm0_resamp4_fixthr30_bbt10_maconcat_rm1 \
    fcpc \
    "weka.classifiers.functions.MultilayerPerceptron -H a,a" \
    28 

#2
./automation.sh \
    ../../data/in/top10-v3/v2_group1_dim64_fwhm2_resamp4_fixthr30_bbt11_maconcat_rm1 \
    fcpc \
    "weka.classifiers.functions.MultilayerPerceptron" \
    46
#3
./automation.sh \
    ../../data/in/top10-v3/v2_group1_dim64_fwhm2_resamp4_fixthr30_bbt11_maconcat_rm1 \
    fcpc \
    "weka.classifiers.functions.MultilayerPerceptron -H a,a" \
    41
#4
./automation.sh \
    ../../data/in/top10-v3/v2_group1_dim64_fwhm2_resamp4_fixthr30_bbt11_maconcat_rm1 \
    fcpc \
    "weka.classifiers.functions.MultilayerPerceptron -H a,a,a" \
    43
#5
./automation.sh \
    ../../data/in/top10-v3/v2_group1_dim64_fwhm2_resamp4_fixthr30_bbt11_maconcat_rm1 \
    fcpc \
    "weka.classifiers.functions.MultilayerPerceptron -H a,a,a" \
    41
#6
./automation.sh \
    ../../data/in/top10-v3/v2_group1_dim71_fwhm4_resamp4_fixthr32_bbt10_maconcat_rm1 \
    fcpc \
    "weka.classifiers.functions.MultilayerPerceptron -H a,a" \
    35
#7
./automation.sh \
    ../../data/in/top10-v3/v2_group1_dim64_fwhm2_resamp4_fixthr30_bbt11_maconcat_rm1 \
    fcpc \
    "weka.classifiers.functions.MultilayerPerceptron -H a,a" \
    39
#8
./automation.sh \
    ../../data/in/top10-v3/v2_group1_dim71_fwhm4_resamp4_fixthr32_bbt10_maconcat_rm1 \
    fcpc \
    "weka.classifiers.functions.MultilayerPerceptron" \
    35
#9 
./automation.sh \
    ../../data/in/top10-v3/v2_group1_dim68_fwhm0_resamp4_fixthr30_bbt10_maconcat_rm1 \
    fcpc \
    "weka.classifiers.functions.MultilayerPerceptron" \
    28 
#10
./automation.sh \
    ../../data/in/top10-v3/v2_group1_dim68_fwhm0_resamp4_fixthr30_bbt10_maconcat_rm1 \
    fcpc \
    "weka.classifiers.functions.MultilayerPerceptron" \
    27

