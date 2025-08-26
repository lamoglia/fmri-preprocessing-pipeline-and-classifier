# abide-metadata-downloader

This is a simple project to download metadata form ABIDE I and II and organize its contents in a single CSV file, so it can be later used for preprocessing and preparing the raw data for creating the classifiers.

## Pre requisitos

- python 3.9
- uv

## Instruções

Para fazer o download dos metadados dos datasets ABIDE I e II:

```
chmod +x src/downloader.sh
./src/downloader.sh
```

Os arquivos serão baixados na pasta `downloaded/`

Após o download, execute os comandos abaixo para organizar os metadados em um arquivo CSV:

```
uv sync
uv run src/generate_csv.py
```

Será gerado um arquivo csv `fmri_scan_parameters_task_rest.csv` com os metadados.