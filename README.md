# 🧠 Modelado Estadístico del Nivel de Estrés en Desarrolladores de Software a partir de Métricas de Productividad y Carga Cognitiva

![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge\&logo=r\&logoColor=white)
![RStudio](https://img.shields.io/badge/RStudio-75AADB?style=for-the-badge\&logo=RStudio\&logoColor=white)
![LaTeX](https://img.shields.io/badge/LaTeX-008080?style=for-the-badge\&logo=latex\&logoColor=white)
![Machine Learning](https://img.shields.io/badge/Machine%20Learning-Regression-orange?style=for-the-badge)
![Statistics](https://img.shields.io/badge/Statistical%20Modeling-OLS-blue?style=for-the-badge)

---

# 📌 Descripción General

Este repositorio contiene el desarrollo completo del proyecto académico **"Modelado Estadístico del Nivel de Estrés en Desarrolladores de Software a partir de Métricas de Productividad y Carga Cognitiva"**, elaborado para la asignatura de Modelos Estocásticos y Estadística Inferencial de la Universidad Politécnica Salesiana.

El objetivo principal consiste en identificar qué variables relacionadas con productividad, desempeño y carga cognitiva explican significativamente el nivel de estrés de desarrolladores de software mediante técnicas de regresión lineal múltiple.

El estudio utiliza un conjunto de datos de 1000 observaciones que simulan métricas de desempeño de desarrolladores asistidos por herramientas de inteligencia artificial.

---

# 🎯 Objetivos

## Objetivo General

Construir un modelo de regresión lineal múltiple capaz de explicar y predecir el nivel de estrés de desarrolladores de software a partir de variables relacionadas con productividad y carga cognitiva.

## Objetivos Específicos

* Realizar limpieza y preparación del conjunto de datos.
* Analizar relaciones entre variables mediante correlaciones.
* Detectar posibles problemas de multicolinealidad.
* Implementar un procedimiento de selección de variables mediante Backward Elimination.
* Evaluar la calidad del modelo utilizando métricas estadísticas.
* Identificar observaciones atípicas e influyentes.
* Validar la capacidad predictiva del modelo sobre datos no observados.

---

# 📊 Dataset Utilizado

**Nombre del Dataset**

AI Developer Performance Extended

**Número de observaciones**

1000 registros

**Variable objetivo**

* Stress_Level

**Variables predictoras iniciales**

* Hours_Coding
* Lines_of_Code
* Bugs_Found
* Bugs_Fixed
* AI_Usage_Hours
* Sleep_Hours
* Cognitive_Load
* Task_Success_Rate
* Coffee_Intake
* Task_Duration_Hours
* Commits
* Errors

---

# 🏗️ Metodología

El desarrollo del proyecto se estructuró en cuatro etapas principales.

## 1️⃣ Limpieza y Preparación de Datos

Se realizó la eliminación de registros incompletos mediante:

```r
data <- na.omit(data)
```

garantizando consistencia estadística para el análisis posterior.

---

## 2️⃣ Análisis Exploratorio de Datos (EDA)

Se calcularon:

* Estadísticas descriptivas
* Matriz de correlaciones
* Análisis de multicolinealidad
* Distribuciones de variables

La correlación entre variables fue evaluada mediante el coeficiente de Pearson.

Se consideró posible multicolinealidad cuando:

```text
|r| > 0.80
```

---

## 3️⃣ Construcción del Modelo

Se dividió el conjunto de datos en:

* 80% Entrenamiento
* 20% Prueba

Posteriormente se implementó un modelo de:

**Regresión Lineal Múltiple (OLS)**

utilizando la función:

```r
lm()
```

La selección de variables se realizó mediante:

**Backward Elimination**

eliminando iterativamente la variable menos significativa según su valor-p.

---

## 4️⃣ Diagnóstico y Validación

Se evaluaron:

### Outliers

Mediante residuales estandarizados:

```r
abs(rstandard(modelo)) > 2
```

### Observaciones Influyentes

Utilizando:

* Leverage (Hat Values)
* Distancia de Cook

### Validación Predictiva

Se calculó el desempeño del modelo sobre el conjunto de prueba mediante:

```r
cor(predicciones, valores_reales)^2
```

---

# 📈 Resultados Principales

## Selección de Variables

El procedimiento Backward Elimination redujo el modelo original de 12 variables a un conjunto óptimo de 4 variables predictoras.

Variables finales:

* Lines_of_Code
* Cognitive_Load
* Task_Success_Rate
* Task_Duration_Hours

---

## Modelo Final

La ecuación obtenida fue:

```text
Stress_Level =
19.892
- 0.001424(Lines_of_Code)
+ 0.900248(Cognitive_Load)
- 0.081973(Task_Success_Rate)
+ 0.044981(Task_Duration_Hours)
```

---

## Bondad de Ajuste

| Métrica                 | Valor   |
| ----------------------- | ------- |
| R²                      | 0.9413  |
| R² Ajustado             | 0.9410  |
| Error Estándar Residual | 5.354   |
| Estadístico F           | 3185    |
| p-valor Global          | < 0.001 |

El modelo explica aproximadamente el **94.1% de la variabilidad observada en el nivel de estrés**.

---

## Validación Externa

Desempeño sobre el conjunto de prueba:

```text
R²_test = 0.9270
```

Esto demuestra una elevada capacidad de generalización.

---

## Diagnóstico de Observaciones

Se detectaron:

| Tipo                  | Cantidad |
| --------------------- | -------- |
| Outliers              | 1        |
| Leverage Alto         | 7        |
| Distancia de Cook > 1 | 0        |

Los resultados indican que el modelo es estable y no se encuentra afectado por observaciones extremadamente influyentes.

---

# ⚙️ Requisitos

## Software

* R 4.0 o superior
* RStudio

## Librerías de R

```r
install.packages("corrplot")
```

---

# 🚀 Ejecución

## 1. Clonar el repositorio

```bash
git clone https://github.com/akedasg3/modelo-estres-devs.git
```

## 2. Abrir RStudio

Abrir el archivo:

```text
modelo_estres_devs.R
```

## 3. Ejecutar el script

Ejecutar todos los bloques de código en orden.

El programa realizará automáticamente:

* Limpieza de datos
* Cálculo de correlaciones
* Construcción del modelo
* Selección de variables
* Detección de outliers
* Validación estadística
* Impresión del modelo final

---

# 🔬 Conclusiones Principales

* La carga cognitiva fue el predictor más importante del nivel de estrés.
* La tasa de éxito en las tareas presentó una relación inversa con el estrés.
* El modelo alcanzó un excelente desempeño explicativo (R² = 0.9413).
* La validación externa confirmó una adecuada capacidad predictiva (R² = 0.9270).
* El proceso de selección permitió reducir significativamente la complejidad del modelo sin perder precisión.

---

# 👨‍🏫 Tutor Académico

**Dr. Diego Fernando Vallejo Huanga**

Universidad Politécnica Salesiana

---

# 👨‍💻 Autores

* David Alejandro Cruz Palacios
* Elvis Paúl García Acevedo 
* Naim Andre Michelena Andrade
* Emily Mabel Ortega Constante 
* Carlos José Pilatuña Roldan 
* Mario Alexander Salazar Serna

Carrera de Ciencias de la Computación

Facultad de Ingeniería

Universidad Politécnica Salesiana

Quito, Ecuador

---

# 📜 Licencia

Este proyecto fue desarrollado con fines académicos y educativos dentro de la Universidad Politécnica Salesiana.
Todos los derechos pertenecen a sus respectivos autores.
