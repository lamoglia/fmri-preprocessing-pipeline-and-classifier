# Preprocessor

Esse projeto executa um pipeline de preprocessamento de imagens de fMRI gerando como saída um arquivo com uma série temporal de cada participante.

Existem dois modos de operação:

1. Modo padrão: realiza o preprocessamento, em conjunto, de imagens de ressonância magnética funcional (fMRI) de um grupo de participantes usando um arquivo de configuração. (Coordenado pelo script `preprocess.sh`)
2. Modo externo: realiza o processamento, um a um, de um segundo conjunto de imagens de ressonância magnética funcional (fMRI), usando as mesmas configurações utilizadas em um preprocessamento executado anteriormente no modo padrão. (Coordenado pelo script `external.sh`)

Maiores detalhes em `CONFIGURACAO.md`

## Docker

Para rodar a imagem  docker e necessário montar alguns volumes:

- `/data/in/fmri`: mapeando o diretório onde estao os arquivos de fMRI a serem preprocessados no formato BIDS para ABIDE1 e ABIDE2

exemplo de estrutura de diretórios:

```
.
├── ABIDE1
│   └── raw
│       └── BIDS
│           ├── CMU_b
│           │   ├── T1w.json
│           │   ├── dataset_description.json
│           │   ├── participants.tsv
│           │   ├── sub-0050643
│           │   ├── sub-0050644
│           │   ├── ...
│           ├── Caltech
│           ├── ...
├── ABIDE2
│   └── raw
│       ├── ABIDEII-BNI_1
│       │   ├── T1w.json
│       │   ├── dataset_description.json
│       │   ├── derivatives
│       │   ├── participants.tsv
│       │   ├── sub-29006
│       │   ├── sub-29007
│       │   ├── ...
│       ├── ABIDEII-EMC_1
│       ├── ABIDEII-ETHZ_1
│       ├── ...
```
- `/data/in/experiments`: diretório contendo os arquivos com as configurações de preprocessamento e das listas de participantes a serem preprocessados
- `/data/out/work_dir`: diretório onde serão criados os arquivos intermediários do preprocessamento, possiblilitando inspeção
- `/data/out/output_dir`: diretório onde serão disponiblizados os resultados dos preprocessamentos 


Exemplo para realizar o preprocessamento padrão usando o arquivo de configuração `experiment.txt`
```bash
docker build . -t preprocess
docker run -it `
    -v E:/data/input:/data/in/fmri `
    -v E:/data/input/slice_order_files:/data/in/slice_order_files `
    -v F:/data/output/fsl/experiments_docker:/data/in/experiments `
    -v F:/data/output/fsl/preprocessor/work:/data/out/work_dir `
    -v F:/data/output/fsl/preprocessor/output:/data/out/output_dir `
    preprocess `
    ./preprocess.sh experiment.txt
```

Exemplo para preprocessar sujeitos externos definidos em `external_participants.txt` usando a mesma configuração de um preprocessamento anterior `20250322_234251_72_participants`
```bash
docker build . -t preprocess
docker run -it `
    -v E:/data/input:/data/in/fmri `
    -v E:/data/input/slice_order_files:/data/in/slice_order_files `
    -v F:/data/output/fsl/experiments_docker:/data/in/experiments `
    -v F:/data/output/fsl/preprocessor/work:/data/out/work_dir `
    -v F:/data/output/fsl/preprocessor/output:/data/out/output_dir `
    preprocess `
    ./external.sh 20250322_234251_72_participants external_participants.txt
```

# Docker compose

Executando via docker compose, as especificações de volumes devem ser definidas no arquivo `docker-compose.yml` e o comando para rodar o script de preprocessamento é o seguinte:

```bash
docker compose run pipeline ./preprocess.sh experiment.txt
```
onde `experiment.txt` é um arquivo de configuração dentro do volume mapeado em `/data/in/experiments`

ou

```bash
docker compose run pipeline ./external.sh 20250409_230347_72_participants external_participants.txt
```