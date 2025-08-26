## Phenotypic data extractor

Scripts auxiliares que leem dados de `participants.tsv` e organizam em um unico arquivo csv.
A saída deste projeto será usada pelo projeto `preprocessing_input_generator`.

## Executando

```bash
uv sync
uv run src/main.py
```

Será gerado um arquivo csv em `data/out/abide_participants_phenotype.csv` com as colunas `abide_version,site,sub_id,group,age,sex,full_iq` a partir dos arquivos de metadados da ABIDE.