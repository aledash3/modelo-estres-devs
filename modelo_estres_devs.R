# -- BLOQUE 1 --
# Librerías

library(corrplot)

# -- BLOQUE 2 --
# Cargar dataset

data <- read.csv(
  "AI_Developer_Performance_Extended_1000.csv" # Modicar ruta según sea necesario
)

# Eliminar valores faltantes

data <- na.omit(data)

# Información disponible para consulta manual

# str(data)
# summary(data)
# names(data)
# dim(data)

# -- BLOQUE 3 --

# Matriz de correlaciones

matriz <- cor(data)

# Gráfico de correlaciones

corrplot(
  matriz,
  method = "color",
  type = "upper"
)

# Para visualizar posteriormente

# matriz

# -- BLOQUE 4 --

# Tabla de multicolinealidad

multicolinealidad <- data.frame()

for(i in 1:(ncol(matriz)-1)){
  
  for(j in (i+1):ncol(matriz)){
    
    if(abs(matriz[i,j]) > 0.80){ # OJO PROBAR CON 0.60
      
      multicolinealidad <- rbind(
        multicolinealidad,
        data.frame(
          Variable_1 = colnames(matriz)[i],
          Variable_2 = colnames(matriz)[j],
          Correlacion = matriz[i,j]
        )
      )
      
    }
    
  }
  
}

# Consultar cuando se desee

# multicolinealidad

# -- BLOQUE 5 --

# División 80% entrenamiento 20% prueba

set.seed(123)

n <- nrow(data)

id_train <- sample(
  1:n,
  size = round(0.80*n)
)

train <- data[id_train,]
test <- data[-id_train,]

# Consultar posteriormente

# dim(train)
# dim(test)

# -- BLOQUE 6 --

# Modelo inicial

formula_actual <-
  Stress_Level ~
  Hours_Coding +
  Lines_of_Code +
  Bugs_Found +
  Bugs_Fixed +
  AI_Usage_Hours +
  Sleep_Hours +
  Cognitive_Load +
  Task_Success_Rate +
  Coffee_Intake +
  Task_Duration_Hours +
  Commits +
  Errors

# -- BLOQUE 7 --

# Historial de modelos

historial <- data.frame()

# Mejor modelo válido

mejor_modelo <- NULL

# Mejor R² Ajustado

mejor_r2_ajustado <- -Inf

# Contador

iteracion <- 1

# -- BLOQUE 8 --

repeat{
  
  modelo <- lm(
    formula_actual,
    data = train
  )
  
  resumen <- summary(modelo)
  
  variables_actuales <-
    attr(
      terms(modelo),
      "term.labels"
    )
  
  cantidad_variables <-
    length(
      variables_actuales
    )
  
  historial <- rbind(
    historial,
    data.frame(
      Iteracion = iteracion,
      Variables = cantidad_variables,
      Variables_Modelo =
        paste(
          variables_actuales,
          collapse = " + "
        ),
      R2 =
        resumen$r.squared,
      R2_Ajustado =
        resumen$adj.r.squared
    )
  )
  
  if(
    cantidad_variables >= 4 &&
    cantidad_variables <= 8
  ){
    
    if(
      resumen$adj.r.squared >
      mejor_r2_ajustado
    ){
      
      mejor_r2_ajustado <-
        resumen$adj.r.squared
      
      mejor_modelo <- modelo
      
    }
    
  }
  
  if(cantidad_variables <= 4){
    
    break
    
  }
  
  pvalores <-
    coef(resumen)[-1,4]
  
  variable_eliminar <-
    names(
      which.max(
        pvalores
      )
    )
  
  variables_actuales <-
    variables_actuales[
      variables_actuales !=
        variable_eliminar
    ]
  
  formula_actual <-
    as.formula(
      paste(
        "Stress_Level ~",
        paste(
          variables_actuales,
          collapse = " + "
        )
      )
    )
  
  iteracion <- iteracion + 1
  
}

# -- BLOQUE 9 --

# Para consultar todos los modelos

# historial

# -- BLOQUE 10 --

# Residuales estandarizados

rs <- rstandard(
  mejor_modelo
)
rstu <- rstudent(
  mejor_modelo
)
outliers <- which(
  abs(rs) > 2
)

df=n-p-1
qt<- qt(0.05/2,df,lower.tail = FALSE)
outliers_rstu <- which(
  abs(rstu) > qt
)

# Consultar

# outliers

# -- BLOQUE 11 --

hi <- influence(
  mejor_modelo
)$hat

p <- length(
  coef(mejor_modelo)
) - 1

umbral_hat <-
  3*(p+1)/
  nrow(train)

influyentes_hat <-
  which(
    hi > umbral_hat
  )

# Consultar

# influyentes_hat

# -- BLOQUE 12 --

cook <- cooks.distance(
  mejor_modelo
)

influyentes_cook <-
  which(
    cook > 1
  )

# Consultar

# influyentes_cook

# -- BLOQUE 13 --

obs_problematicas <- unique(
  c(
    outliers,
    influyentes_hat,
    influyentes_cook
  )
)

train_limpio <- train

if(length(obs_problematicas) > 0){
  
  train_limpio <- train[
    -obs_problematicas,
  ]
  
}

modelo_limpio <- lm(
  formula(mejor_modelo),
  data = train_limpio
)

# -- BLOQUE 14 --

comparacion <- data.frame(
  
  Modelo =
    c(
      "Modelo_A",
      "Modelo_B"
    ),
  
  R2_Ajustado =
    c(
      summary(mejor_modelo)$adj.r.squared,
      summary(modelo_limpio)$adj.r.squared
    )
)

# Consultar

# comparacion

# -- BLOQUE 15 -- 

if(
  summary(modelo_limpio)$adj.r.squared >
  summary(mejor_modelo)$adj.r.squared
){
  
  modelo_final <- modelo_limpio
  
}else{
  
  modelo_final <- mejor_modelo
  
}

# ÚNICA SALIDA AUTOMÁTICA

summary(modelo_final)

pred <- predict(modelo_final, newdata=test)

cor(pred, test$Stress_Level)^2

# Validación sobre datos de prueba (20%)

predicciones <- predict(modelo_final, newdata = test)

SS_res <- sum((test$Stress_Level - predicciones)^2)
SS_tot <- sum((test$Stress_Level - mean(test$Stress_Level))^2)

r2_test <- 1 - (SS_res / SS_tot)

# SALIDA
r2_test

# -- BLOQUE 16 --
# Gráficos de supuestos del modelo

par(mfrow = c(2, 2))

# 1. Residuos vs Valores Ajustados (Homocedasticidad)
plot(
  modelo_final,
  which = 1,
  main = "Residuos vs Valores Ajustados"
)

# 2. QQ-Plot (Normalidad de errores)
plot(
  modelo_final,
  which = 2,
  main = "QQ-Plot de Residuales"
)
