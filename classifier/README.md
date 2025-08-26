# Classificador ASD/TD

Esse projeto executa a partir dos os arquivos preprocessados, extração de características (feature extraction), seleção de características (feature selection), treinamento e teste de diversos classificadores ASD/TD.

## Docker

Para rodar a imagem  docker e necessário montar dois volumes:
- um em `/data/out/output_dir`: mapeando o diretório em que serão escritos os arquivos de saída (output) dos classificadores
- outro em `/data/in/preprocessed`: mapeando o diretório onde estão os arquivos preprocessados de entrada (saída do preprocessamento) a serem usados para a classificação

Exemplo
```bash
docker build . -t classifier

docker run -it \
    -v ./data/out:/data/out/output_dir \
    -v ./data/in:/data/in/preprocessed \
    classifier \
    ./automation.sh top10-v3/v2_group1_dim64_fwhm2_resamp4_fixthr30_bbt11_maconcat_rm1 fcpc "weka.classifiers.functions.MultilayerPerceptron -H a,a" 20 10
```

O comando irá gerar na pasta especificada como saída duas outras pastas:
- `logs/` : contendo os arquivos de log da execução
- `top10-v3/v2_group1_dim64_fwhm2_resamp4_fixthr30_bbt11_maconcat_rm1/`: (diretório com o mesmo nome informado na input) contendo as sub-pastas:
    - `dual_regression_copy/`: uma cópia dos arquivos preprocessados utilizados
    - `summary/`: diretório principal com os resultados dos classificadores
        - `summary.csv`: resumo dos resultados contendo acurácia, especificidade, sensibilidade, precisão e f-score
        - `summary_high_precision_only.csv`: resumo dos resultados, exibindo somente os classificadores que tiveram os melhores resultados
    - `training_input/`: diretório com os arquivos de entrada usados para o treinamento e teste dos classificadores - são os arquivos com as features selecionadas (FC,PC ou FC+PC)
    - `weka_results/`: diretório com os resultados brutos do Weka

## Docker compose

Caso use o docker compose, os volumes devem ser definidos no arquivo `docker-compose.yml` e o comando para rodar o script de classificação e o seguinte:

```bash
docker compose run training ./automation.sh <diretório-output-do-preprocessamento> <tipo-de-feature> <classificador> <numero-de-features>
```
Onde:
- `diretório-output-do-preprocessamento`: Nome da pasta de output do preprocessamento, diretório deve conter a pasta `dual_regression/` com as series temporais de cada participante (`dr_stage1_subject00000.txt`, `dr_stage1_subject00001.txt`, ...) e o arquivo `experiment_definition.txt` com as especificações do preprocessamento usado. Deve ser o nome da pasta ou um caminho relativo dentro de `/data/in/preprocessed/` (volume).
- `tipo-de-feature`: Tipo de feature a ser usado, pode ser `fc` (full correlation), `pc`(partial correlation) ou `fcpc`(full correlation + partial correlation). Inform `all` para testar todas as variacoes.
- `classificador`: Classificador a ser usado, pode ser um dos listados abaixo. (especifique `all`  para testar todos os classificadores)
- `numero-de-features`: Número de features a serem usadas no classificador. Omita para testar com todas as variações de número de features.

exemplo:
```bash
docker compose run training ./automation.sh 20250322_234251_72_participants fcpc "weka.classifiers.functions.MultilayerPerceptron -H a,a" 20
docker compose run training ./automation.sh ext_20250326_122807_external_participants fcpc "weka.classifiers.functions.MultilayerPerceptron -H a,a" 20
```

Classificadores disponiveis

- "weka.classifiers.bayes.NaiveBayes" #https://weka.sourceforge.io/doc.dev/weka/classifiers/bayes/NaiveBayes.html
- "weka.classifiers.functions.LDA" #https://weka.sourceforge.io/doc.packages/discriminantAnalysis/weka/classifiers/functions/LDA.html
- "weka.classifiers.functions.LibLINEAR" #https://weka.sourceforge.io/doc.stable/weka/classifiers/functions/LibLINEAR.html
- "weka.classifiers.functions.MultilayerPerceptron" #https://weka.sourceforge.io/doc.dev/weka/classifiers/functions/MultilayerPerceptron.html
- "weka.classifiers.functions.MultilayerPerceptron -H a,a"
- "weka.classifiers.functions.MultilayerPerceptron -H a,a,a"
- "weka.classifiers.functions.RBFClassifier" #https://weka.sourceforge.io/doc.packages/RBFNetwork/weka/classifiers/functions/RBFClassifier.html
- "weka.classifiers.functions.SGD" #https://weka.sourceforge.io/doc.dev/weka/classifiers/functions/SGD.html
- "weka.classifiers.functions.SMO" #https://weka.sourceforge.io/doc.dev/weka/classifiers/functions/SMO.html
- "weka.classifiers.meta.ClassificationViaClustering" #https://weka.sourceforge.io/doc.stable/weka/classifiers/meta/ClassificationViaClustering.html
- "weka.classifiers.trees.FT" #https://weka.sourceforge.io/doc.packages/functionalTrees/weka/classifiers/trees/FT.html
- "weka.classifiers.trees.HoeffdingTree" #https://weka.sourceforge.io/doc.dev/weka/classifiers/trees/HoeffdingTree.html
- "weka.classifiers.trees.SysFor" #https://github.com/zislam/SysFor/blob/master/src/weka/classifiers/trees/SysFor.java