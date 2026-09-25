from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import mysql.connector

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="soporte_app"
    )

class IncidenciaNueva(BaseModel):
    nombre_usuario: str
    correo: str
    numero_equipo: int
    descripcion: str
    prioridad: str
    estado: str

@app.get("/incidencias")
def obtener_incidencias():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM incidencias")
    datos = cursor.fetchall()
    
    for d in datos:
        if d['fecha_registro']:
            d['fecha_registro'] = d['fecha_registro'].isoformat()
            
    conn.close()
    return datos

@app.post("/incidencias")
def crear_incidencia(inc: IncidenciaNueva):
    conn = get_db_connection()
    cursor = conn.cursor()
    query = "INSERT INTO incidencias (nombre_usuario, correo, numero_equipo, descripcion, prioridad, estado) VALUES (%s, %s, %s, %s, %s, %s)"
    cursor.execute(query, (inc.nombre_usuario, inc.correo, inc.numero_equipo, inc.descripcion, inc.prioridad, inc.estado))
    conn.commit()
    conn.close()
    return {"mensaje": "Creado exitosamente"}

@app.put("/incidencias/{id}")
def actualizar_incidencia(id: int, inc: IncidenciaNueva):
    conn = get_db_connection()
    cursor = conn.cursor()
    query = "UPDATE incidencias SET nombre_usuario=%s, correo=%s, numero_equipo=%s, descripcion=%s, prioridad=%s, estado=%s WHERE id=%s"
    cursor.execute(query, (inc.nombre_usuario, inc.correo, inc.numero_equipo, inc.descripcion, inc.prioridad, inc.estado, id))
    conn.commit()
    conn.close()
    return {"mensaje": "Actualizado"}

@app.delete("/incidencias/{id}")
def eliminar_incidencia(id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM incidencias WHERE id=%s", (id,))
    conn.commit()
    conn.close()
    return {"mensaje": "Eliminado"}