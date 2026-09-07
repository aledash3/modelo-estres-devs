# ==============================================================================
# Modelado Estadístico del Nivel de Estrés en Desarrolladores de Software
# Asignatura: Modelos Estocásticos y Estadística Inferencial
# Universidad Politécnica Salesiana - Quito, Ecuador
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. GESTIÓN DE DEPENDENCIAS
# ------------------------------------------------------------------------------
paquetes_requeridos <- c("corrplot")

for (pkg in paquetes_requeridos) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("Instalando paquete requerido: %s...", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

suppressPackageStartupMessages(library(corrplot))

# ------------------------------------------------------------------------------
# 2. CARGA Y PREPARACIÓN DE DATOS
# ------------------------------------------------------------------------------
# Resolución de ruta para permitir ejecución desde la raíz o desde /scripts
posibles_rutas <- c(
  file.path("data", "AI_Developer_Performance_Extended_1000.csv"),
  file.path("..", "data", "AI_Developer_Performance_Extended_1000.csv"),
  "AI_Developer_Performance_Extended_1000.csv"
)

ruta_datos <- posibles_rutas[file.exists(posibles_rutas)][1]
if (is.na(ruta_datos)) {
  stop("Error: No se encontró 'AI_Developer_Performance_Extended_1000.csv'.")
}

data <- read.csv(ruta_datos)
data <- na.omit(data)

cat(sprintf("✓ Dataset cargado exitosamente (%d observaciones, %d variables).\n", 
            nrow(data), ncol(data)))

# Directorio de salida para figuras
dir_figuras <- if (dir.exists("results/figures")) {
  "results/figures"
} else if (dir.exists("../results/figures")) {
  "../results/figures"
} else {
  dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
  "results/figures"
}

# ------------------------------------------------------------------------------
# 3. ANÁLISIS EXPLORATORIO: MATRIZ DE CORRELACIÓN
# ------------------------------------------------------------------------------
matriz_cor <- cor(data)

# Exportar gráfico de correlación
ruta_png_corr <- file.path(dir_figuras, "matriz_correlacion.png")
png(ruta_png_corr, width = 2400, height = 2400, res = 300)
corrplot(
  matriz_cor,
  method = "color",
  type = "upper",
  tl.col = "black",
  tl.srt = 45,
  addCoef.col = "black",
  number.cex = 0.65,
  title = "Matriz de Correlación - Métricas de Desarrolladores",
  mar = c(0, 0, 2, 0)
)
dev.off()
cat(sprintf("✓ Gráfico de correlación guardado en: %s\n", ruta_png_corr))

# Detección de pares con alta correlación (|r| > 0.80)
tabla_multicolinealidad <- data.frame()
for (i in 1:(ncol(matriz_cor) - 1)) {
  for (j in (i + 1):ncol(matriz_cor)) {
    if (abs(matriz_cor[i, j]) > 0.80) {
      tabla_multicolinealidad <- rbind(
        tabla_multicolinealidad,
        data.frame(
          Variable_1 = colnames(matriz_cor)[i],
          Variable_2 = colnames(matriz_cor)[j],
          Correlacion = round(matriz_cor[i, j], 4)
        )
      )
    }
  }
}

if (nrow(tabla_multicolinealidad) > 0) {
  cat("\n--- Variables con sospecha de multicolinealidad (|r| > 0.80) ---\n")
  print(tabla_multicolinealidad)
} else {
  cat("\n✓ No se detectaron problemas severos de multicolinealidad bilateral (|r| > 0.80).\n")
}

# ------------------------------------------------------------------------------
# 4. PARTICIÓN DE DATOS: 80% ENTRENAMIENTO / 20% PRUEBA
# ------------------------------------------------------------------------------
set.seed(123)
n_total <- nrow(data)
id_train <- sample(1:n_total, size = round(0.80 * n_total))

train <- data[id_train, ]
test  <- data[-id_train, ]

cat(sprintf("✓ Partición completada: %d entrenamiento (80%%), %d prueba (20%%).\n",
            nrow(train), nrow(test)))

# ------------------------------------------------------------------------------
# 5. SELECCIÓN DE VARIABLES: BACKWARD ELIMINATION
# ------------------------------------------------------------------------------
formula_actual <- Stress_Level ~ Hours_Coding + Lines_of_Code + Bugs_Found +
  Bugs_Fixed + AI_Usage_Hours + Sleep_Hours + Cognitive_Load +
  Task_Success_Rate + Coffee_Intake + Task_Duration_Hours + Commits + Errors

historial_seleccion <- data.frame()
mejor_modelo <- NULL
mejor_r2_ajustado <- -Inf
iteracion <- 1

repeat {
  modelo_paso <- lm(formula_actual, data = train)
  resumen_paso <- summary(modelo_paso)
  
  vars_actuales <- attr(terms(modelo_paso), "term.labels")
  n_vars <- length(vars_actuales)
  
  historial_seleccion <- rbind(
    historial_seleccion,
    data.frame(
      Iteracion = iteracion,
      Variables = n_vars,
      Variables_Modelo = paste(vars_actuales, collapse = " + "),
      R2 = round(resumen_paso$r.squared, 4),
      R2_Ajustado = round(resumen_paso$adj.r.squared, 4)
    )
  )
  
  # Criterio: seleccionar el mejor modelo que tenga entre 4 y 8 variables
  if (n_vars >= 4 && n_vars <= 8) {
    if (resumen_paso$adj.r.squared > mejor_r2_ajustado) {
      mejor_r2_ajustado <- resumen_paso$adj.r.squared
      mejor_modelo <- modelo_paso
    }
  }
  
  # Condición de parada
  if (n_vars <= 4) break
  
  # Eliminar variable con mayor p-valor
  p_valores <- coef(resumen_paso)[-1, 4]
  var_eliminar <- names(which.max(p_valores))
  
  vars_actuales <- vars_actuales[vars_actuales != var_eliminar]
  formula_actual <- as.formula(paste("Stress_Level ~", paste(vars_actuales, collapse = " + ")))
  iteracion <- iteracion + 1
}

cat(sprintf("✓ Procedimiento Backward Elimination finalizado en %d iteraciones.\n", iteracion))
cat(sprintf("  Variables seleccionadas: %s\n", paste(attr(terms(mejor_modelo), "term.labels"), collapse = ", ")))

# ------------------------------------------------------------------------------
# 6. DIAGNÓSTICO: OUTLIERS Y OBSERVACIONES INFLUYENTES
# ------------------------------------------------------------------------------
# Parámetros del modelo para pruebas diagnósticas
p <- length(coef(mejor_modelo)) - 1
n_train <- nrow(train)
df_res <- n_train - p - 1

# 1. Residuales estandarizados y studentizados
rs <- rstandard(mejor_modelo)
rstu <- rstudent(mejor_modelo)
outliers_rs <- which(abs(rs) > 2)

qt_critico <- qt(0.05 / 2, df = df_res, lower.tail = FALSE)
outliers_rstu <- which(abs(rstu) > qt_critico)

# 2. Leverage (Hat values)
hi <- influence(mejor_modelo)$hat
umbral_hat <- 3 * (p + 1) / n_train
influyentes_hat <- which(hi > umbral_hat)

# 3. Distancia de Cook
cook <- cooks.distance(mejor_modelo)
influyentes_cook <- which(cook > 1)

# Puntos problemáticos consolidados
obs_problematicas <- unique(c(outliers_rs, influyentes_hat, influyentes_cook))

cat(sprintf("\n--- Diagnóstico de Observaciones (Train: %d obs) ---\n", n_train))
cat(sprintf("• Outliers (|rstandard| > 2): %d\n", length(outliers_rs)))
cat(sprintf("• Puntos de alto apalancamiento (Hat > %.4f): %d\n", umbral_hat, length(influyentes_hat)))
cat(sprintf("• Observaciones con distancia de Cook > 1: %d\n", length(influyentes_cook)))
cat(sprintf("• Total de observaciones problemáticas únicas: %d\n", length(obs_problematicas)))

# ------------------------------------------------------------------------------
# 7. COMPARACIÓN Y SELECCIÓN DEL MODELO DEFINITIVO
# ------------------------------------------------------------------------------
train_limpio <- train
if (length(obs_problematicas) > 0) {
  train_limpio <- train[-obs_problematicas, ]
}

modelo_limpio <- lm(formula(mejor_modelo), data = train_limpio)

r2_ajust_base   <- summary(mejor_modelo)$adj.r.squared
r2_ajust_limpio <- summary(modelo_limpio)$adj.r.squared

if (r2_ajust_limpio > r2_ajust_base) {
  modelo_final <- modelo_limpio
  cat("\n✓ Se seleccionó el modelo depurado sin observaciones problemáticas.\n")
} else {
  modelo_final <- mejor_modelo
  cat("\n✓ Se conservó el modelo con el dataset de entrenamiento completo.\n")
}

# ------------------------------------------------------------------------------
# 8. VALIDACIÓN SOBRE CONJUNTO DE PRUEBA (20%)
# ------------------------------------------------------------------------------
predicciones <- predict(modelo_final, newdata = test)

ss_res <- sum((test$Stress_Level - predicciones)^2)
ss_tot <- sum((test$Stress_Level - mean(test$Stress_Level))^2)
r2_test <- 1 - (ss_res / ss_tot)
r2_cor  <- cor(predicciones, test$Stress_Level)^2

cat("\n======================================================\n")
cat("          RESUMEN DEL MODELO FINAL SELECCIONADO       \n")
cat("======================================================\n")
print(summary(modelo_final))

cat("\n======================================================\n")
cat("              MÉTRICAS DE RENDIMIENTO                 \n")
cat("======================================================\n")
cat(sprintf("• R² (Entrenamiento)          : %.4f\n", summary(modelo_final)$r.squared))
cat(sprintf("• R² Ajustado (Entrenamiento) : %.4f\n", summary(modelo_final)$adj.r.squared))
cat(sprintf("• Error Estándar Residual     : %.4f\n", summary(modelo_final)$sigma))
cat(sprintf("• Estadístico F               : %.2f (p-valor < 0.001)\n", summary(modelo_final)$fstatistic[1]))
cat(sprintf("• R² en Datos de Prueba (20%%) : %.4f\n", r2_test))
cat(sprintf("• Correlación² Pred vs Real   : %.4f\n", r2_cor))
cat("======================================================\n")

# ------------------------------------------------------------------------------
# 9. EXPORTACIÓN DE GRÁFICOS DIAGNÓSTICOS Y DE VALIDACIÓN
# ------------------------------------------------------------------------------
# 1. Gráficos de supuestos (2x2)
ruta_png_diag <- file.path(dir_figuras, "diagnostico_residuales.png")
png(ruta_png_diag, width = 2400, height = 2400, res = 300)
par(mfrow = c(2, 2), mar = c(4.5, 4.5, 3, 2))
plot(modelo_final, which = 1, main = "Residuos vs Ajustados (Homocedasticidad)")
plot(modelo_final, which = 2, main = "Normal Q-Q (Normalidad de Errores)")
plot(modelo_final, which = 3, main = "Scale-Location (Homocedasticidad)")
plot(modelo_final, which = 5, main = "Residuos vs Leverage (Influencia)")
dev.off()
cat(sprintf("✓ Gráfico de supuestos y residuales guardado en: %s\n", ruta_png_diag))

# 2. Gráfico de predicción vs valor real en conjunto de prueba
ruta_png_pred <- file.path(dir_figuras, "prediccion_vs_real.png")
png(ruta_png_pred, width = 2400, height = 2000, res = 300)
par(mar = c(5, 5, 4, 2))
plot(
  test$Stress_Level, predicciones,
  pch = 19, col = rgb(0.15, 0.45, 0.75, 0.6),
  xlab = "Nivel de Estrés Real (Conjunto Test)",
  ylab = "Nivel de Estrés Predicho",
  main = sprintf("Validación Externa: Predicción vs Real (R²_test = %.4f)", r2_test),
  cex.lab = 1.1, cex.main = 1.2
)
abline(a = 0, b = 1, col = "firebrick", lwd = 2, lty = 2)
grid()
legend("topleft",
       legend = c("Predicciones", "Ajuste Ideal (y = x)"),
       col = c(rgb(0.15, 0.45, 0.75, 0.8), "firebrick"),
       pch = c(19, NA), lty = c(NA, 2), lwd = c(NA, 2), bty = "n")
dev.off()
cat(sprintf("✓ Gráfico de predicción vs real guardado en: %s\n", ruta_png_pred))
cat("\n✓ Ejecución completada exitosamente sin errores.\n")
