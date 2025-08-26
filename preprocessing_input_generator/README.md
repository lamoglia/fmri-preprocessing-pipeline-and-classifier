# preprocessing_input_generator

Gera um arquivo csv contendo os dados necessários para execução do preprocessamento e treinamento do modelo de classificação.

## Pre requisitos 

Install uv (linux ubuntu/mint)
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Executando

```bash
uv sync
uv run src/main.py
```

Irá ler os arquivos de entrada 
- `site_params.csv` : Dados sobre cada site ABIDE
- `subject_params.csv` : Arquivo com metadados extraídos dos arquivos nifti (gerado com `data_extractor_from_raw_fmri`)
- `abide_participants_phenotype.csv` : Arquivo com metadados de cada participante do dataset ABIDE, incluindo a classificação ASD/Controle (gerado com `phenotypic-data-extractor`)

e gerar o arquivo `preprocessing_input_generator/data/out/preproc_params.csv`, usado durante o preprocessamento e treinamento do modelo de classificação.

