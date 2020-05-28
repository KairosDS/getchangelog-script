# ChangeLogEvidencias

## Cambios iniciales

1. Crear el fichero `repositories`

    ```console
    cp repositories.default repositories
    ```

2. Rellenar el fichero repositories con una una linea por cada repo. Se puede indicar

   * la URL, HTTP/SSH del repositorio (sin el .git)
   * o una ruta local relativa o absoluta al repo por linea (debe empezar por `.` o `/`)

    Ejemplo:

    ```text
    ssh://git@gitlab.com:kairosds/products/repo1
    ../repo2
    /Users/me/Code/Kairos/repo3
   ```

3. Cambiar los permisos al script para poderle ejecutar

    ```console
    chmod 744 get-evidencias.sh
    ```

## Obtener evidencias

```console
./get-evidencias <nombreUsuarioRepositorio> [true/false] [false/true]
```

* Primer parámetro: Nombre usuario por el que filtrar (puede valer solo una parte)
* Segundo parámetro: ¿Hacer pull del repo? Por defecto `true`.
* Tercer parámetro: indica si se desean borrar los repos vacios del fichero de `repositories`. Por defecto `false`.

## Lugar de las evidencias

./gitlogs dividos por mes y repositorio

## Más información

Dentro de get-evidencias.sh hay comentarios que explican el comportamiento del script
