 
 /*------------------------------------------------------------------------
    File        : PagingManagerList
    Purpose     : 1) Centralizar la logica de paginacion: Proporciona una solucion unica y reutilizable que puede ser implementada para diferentes modulos de la aplicacion, como la gestion de clientes, productos, etc...

2) Facilitar el manejo de grandes cantidades de datos: Permite la carga y presentacion de datos de manera segmentada, mejorando el rendimiento y la experiencia de usuario.

3) Flexibilidad y escalabilidad: Ofrece una estructura flexible que se adapta a cualquier tipo de datos o entidad dentro de la aplicacion.
    Syntax      : 
    Description : Esta clase es una utilidad generica disenada para gestionar el paginado de resultados en distintas partes de la aplicacion, tales como clientes, articulos y cualquier otra entidad que requiera mostrar datos de forma paginada. Esta clase abstrae la logica de paginacion para que pueda ser reutilizada y configurada facilmente para diferentes tipos de datos, optimizando la experiencia de usuario al navegar grandes conjuntos de resultados de manera eficiente. Por el momento se segmentara en diferentes metodos segun la entidad.
    Author(s)   : bsantiago
    Created     : Thu Sep 26 11:25:35 BOT 2024
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS PagingManagerList: 

END CLASS.