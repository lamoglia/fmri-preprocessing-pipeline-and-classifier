# Preprocessamento de imagens de ressonância magnética funcional com FSL

Esse projeto visa facilitar o preprocessamento de imagens de ressonância magnética funcional (fMRI) com a ferramenta FSL (FMRIB Software Library).

Os dados de entrada são as ressonâncias magnéticas funcionais (fMRI) de um grupo de pacientes.
A base de imagens ABIDE I e II foi usada para a implementação e validação do projeto.

Além dos arquivos de ressonância magnética, são usados dois outros arquivos: um com a parametrização do preprocessamento e outro comntendo informações sobre as imagens de ressonância magnética.

## Pré-requisitos

O sistema foi desenvolvido e testado usando Ubuntu 22.04 LTS.

Dependências: 
- FSL 6.0.7.4 (ver `install_fsl.sh`)

## Executando

Para realizar um preprocessamento, um arquivo de configuração de preprocessamento deve ser criado.
Abaixo segue um exemplo:

```txt
BET_FRACTIONAL_INTENSITY_THRESHOLD=0.3
BET_VERTICAL_GRADIENT_THRESHOLD=0
FEAT_SPATIAL_SMOOTHING_FWHM=6.0
FEAT_RESAMPLING_RESOLUTION_MM=4
FEAT_DELETE_VOLUMES=3
FEAT_BRAIN_BACKGROUND_THRESHOLD=10
MELODIC_DIMENSIONALITY_REDUCTION=25
MELODIC_APPROACH="concat"
SUBJECTS="/home/user/projects/fsl/experiments/group1.txt"
FIX_THRESHOLD_PARAMETER=30
FIX_REGRESS_MOTION=1
DR_NORMALIZE=1
```

Abaixo estão descritos cada um dos parâmetros:

### BET_FRACTIONAL_INTENSITY_THRESHOLD

Esse parâmetro é usado na etapa de remoção do crânio (skull stripping).

Quanto maior o valor, maior a chance de remoção de tecido cerebral (o que não é desejável).

Valores válidos: entre 0 e 1 (default 0.5)

### BET_VERTICAL_GRADIENT_THRESHOLD

Esse parâmetro é usado na etapa de remoção do crânio (skull stripping).

Ao definir um valor diferente de zero, a ferramenta de extração de cérebro (BET) irá variar linearmente o valor do parâmetro `BET_FRACTIONAL_INTENSITY_THRESHOLD` de acordo com o número da fatia (slice number) sendo processada, de modo que valores menores sejam aplicados nas fatias mais inferiores e maiores nas fatias mais superiores (ou vice-versa).

Pode ser útil para corrigir problemas de intensidade de sinal em imagens de ressonância magnética.

Valores válidos: entre -1 e 1 (default 0)

###  FEAT_SPATIAL_SMOOTHING_FWHM

Valor (em milímetros) que define o tamanho do kernel gaussiano usado para suavizar a imagem.

Suavização espacial em geral é usada para melhorar a relação sinal-ruído.

Não há regra geral para definir esse valor, mas em geral considera-se algo em torno de 3 vezes o tamanho do voxel (se o voxel é 3x3x3 mm, usar 9).

Valores válidos: Valores positivos

### FEAT_RESAMPLING_RESOLUTION_MM

Valor em milímetros do voxel isotrópico desejado dos dados resampleados.

Para reduzir espaco em disco e uso de memória durante a análise, é aconselhável resamplear os dados filtrados no espaco padrão, mas mantendo a resolução resampleada na resolução da fMRI (tipicamente 4mm ou 5mm).

Valores válidos: Valores positivos

### FEAT_DELETE_VOLUMES

Número de volumes a serem removidos do início da série temporal.
Esses volumes são tipicamente descartados pois foram capturados antes da estabilização do sinal.

Valores válidos: Valores positivos

### FEAT_BRAIN_BACKGROUND_THRESHOLD

Representa um valor percentual que define o limiar de intensidade de sinal para a extração de cérebro.

Valores válidos: Entre 0 e 100

### MELODIC_DIMENSIONALITY_REDUCTION

Número de componentes principais a serem extraídos da série temporal.
 
Caso o valor informado seja 0, o número de componentes principais sera automaticamente estimado. (http://www.fmrib.ox.ac.uk/analysis/techrep/tr02cb1/tr02cb1/)
Valores válidos: inteiros positivos

### MELODIC_APPROACH

"concat" - realiza concatenação temporal das imagens de ressonância magnética funcional (fMRI) de todos os sujeitos antes de realizar a análise de componentes independentes (ICA).

"group" - utiliza a abordagem TICA (Tensorial Independent Component Analysis)

Valores válidos: "concat" ou "group"

### SUBJECTS

Caminho para o arquivo contendo a lista de imagens a serem processadas.
Deve ser um arquivo CSV separado por vírgulas ',', sem cabeçalho e com as seguintes colunas:

```csv
abide_version,site,sub_id,group,age,sex,full_iq,tr_seconds,slice_timing_file,total_volumes,functional_fmri_file,anatomical_fmri_file,total_voxels
```

ex: 

```csv
ABIDE1,NYU,50952,ASD,8.74,F,134.0,2.0,ABIDE1_NYU_slice_timing.txt,180,ABIDE1/raw/BIDS/NYU/sub-0050952/func/sub-0050952_task-rest_run-1_bold.nii.gz,ABIDE1/raw/BIDS/NYU/sub-0050952/anat/sub-0050952_T1w.nii.gz,30412800
ABIDE1,NYU,50953,ASD,11.764,F,132.0,2.0,ABIDE1_NYU_slice_timing.txt,180,ABIDE1/raw/BIDS/NYU/sub-0050953/func/sub-0050953_task-rest_run-1_bold.nii.gz,ABIDE1/raw/BIDS/NYU/sub-0050953/anat/sub-0050953_T1w.nii.gz,30412800
ABIDE1,NYU,50954,ASD,14.75,F,78.0,2.0,ABIDE1_NYU_slice_timing.txt,180,ABIDE1/raw/BIDS/NYU/sub-0050954/func/sub-0050954_task-rest_run-1_bold.nii.gz,ABIDE1/raw/BIDS/NYU/sub-0050954/anat/sub-0050954_T1w.nii.gz,30412800
```

os campos age, sex, full_iq são usados apenas para agrupamento de dados

### FIX_THRESHOLD_PARAMETER

Usado na remoção de ruído.

Um valor menor resultará em uma limpeza mais conservadora (ou seja, menos chance de que bons componentes sejam removidos), enquanto um valor maior resultará em uma limpeza mais agressiva. Normalmente são usados valores entre 5 e 20

Valores entre 0 e 100

### FIX_REGRESS_MOTION

Remoção de ruído (movimento).

Valores possíveis: 1 (ativado) ou 0 (desativado)

### DR_NORMALIZE

Determina se será realizada a normalização de variância nas séries temporais.

Valores possíveis: 1 (ativado) ou 0 (desativado)

