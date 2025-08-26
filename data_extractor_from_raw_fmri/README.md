Esse projeto possui scripts auxiliares para extrair TR e Voxel size diretamente dos headers dos arquivos nifti

```bash
uv sync
uv run src/extract.py <functional nii.gz path> --tr
uv run src/extract.py <functional nii.gz path> --size
```
