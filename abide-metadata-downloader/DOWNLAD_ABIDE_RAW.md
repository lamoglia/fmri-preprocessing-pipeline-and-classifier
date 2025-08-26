# Como baixar os dadataset ABIDE (raw)

### Instalar cyberduck (linux ubuntu/mint)

```
echo -e "deb https://s3.amazonaws.com/repo.deb.cyberduck.io stable main" | sudo tee /etc/apt/sources.list.d/cyberduck.list > /dev/null
sudo apt-get install duck
```

### Listar arquivos

Exemplos

```
duck --anonymous -l s3:fcp-indi/data/Projects/
duck --anonymous -l s3:fcp-indi/data/Projects/ABIDE/
duck --anonymous -l s3:fcp-indi/data/Projects/ABIDE2/
duck --anonymous -l s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/NYU/sub-0050952/
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/NYU/sub-0050952/ .
duck --anonymous -l s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/
duck --anonymous -l s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/sidecards/
```

# Download ABIDE I

Exemplos

```
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/CMU_b/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/Caltech/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/KKI/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/Leuven_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/Leuven_2/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/MaxMun_a/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/MaxMun_b/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/MaxMun_c/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/MaxMun_d/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/NYU/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/OHSU/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/Olin/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/Pitt/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/SBL/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/SDSU/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/Stanford/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/Trinity/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/UCLA_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/UCLA_2/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/UM_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/UM_2/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/USM/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/Yale/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/sidecards/ .
```


# Download ABIDE II

Exemplos

```
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-BNI_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-EMC_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-ETHZ_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-GU_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-IP_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-IU_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-KKI_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-KUL_3/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-NYU_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-NYU_2/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-OHSU_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-ONRC_2/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-SDSU_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-TCD_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-UCD_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-UCLA_1/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-UCLA_Long/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-UPSM_Long/ .
duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/ABIDEII-USM_1/ .
```
