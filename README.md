# Resumo

O repositório é composto por diversos subprojetos que trabalham em conjunto para processar, organizar e analisar dados de fMRI do dataset ABIDE. 

Esses subprojetos são integrados para formar um pipeline completo, desde a coleta e organização de dados até a análise e classificação.

Dentro da pasta de cada um deles há um arquivo README com informações detalhadas sobre sua funcionalidade e uso.

# Estrutura do Repositório

## Abide Metadata Downloader:

Faz o download de metadados dos datasets ABIDE I e II.
Organiza os metadados em um arquivo CSV para uso posterior no preprocessamento e criação de classificadores.

## Phenotypic Data Extractor:

Extrai e organiza dados fenotípicos dos arquivos participants.tsv em um único arquivo CSV.
A saída é utilizada pelo projeto preprocessing_input_generator.

## Data Extractor from Raw fMRI:

Scripts auxiliares para extrair informações como TR e Voxel size diretamente dos headers dos arquivos NIfTI.

## Preprocessing Input Generator:

Gera um arquivo CSV com os dados necessários para o preprocessamento e treinamento de modelos de classificação.
Utiliza como entrada arquivos gerados por outros subprojetos, como phenotypic-data-extractor e data_extractor_from_raw_fmri.

## Preprocessor:

Projeto principal. Realiza o preprocessamento de imagens de fMRI, gerando séries temporais para cada participante.
Utiliza dados no formato BIDS para ABIDE I e II.

## Classifier:

Realiza extração e seleção de características, treinamento e teste de classificadores ASD/TD.
Utiliza os dados preprocessados como entrada e gera resultados detalhados, incluindo métricas como acurácia, especificidade, sensibilidade e f1-score.
 


---

Esse software é resultado do projeto Demanda Universal da Fapemig - `APQ-01565-18`