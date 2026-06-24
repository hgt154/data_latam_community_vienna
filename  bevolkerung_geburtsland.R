install.packages("tidyr")
install.packages("plotly")
install.packages("gapminder")
install.packages("ggrepel")

# Instalando e carregando o pacote showtext
install.packages("showtext")
library(showtext)

# Adicionando suporte a fontes do Google Fonts
font_add_google("Roboto", "roboto")

# Ativando o showtext
showtext_auto()

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
library(plotly)
library(gapminder)
library(scales)
library(ggrepel)  # Pacote para evitar sobreposição de rótulos



############################

# 1. Ler o arquivo, ignorando a primeira linha (o título)
df <- read.csv("bevolkerung_geburtslandOGD.csv", sep = ";", header = FALSE, skip = 1, stringsAsFactors = FALSE)

# 2. Atribuir a segunda linha (agora a primeira) como os nomes das colunas
colnames(df) <- df[1, ]

# 3. Remover a linha com os nomes das colunas
df <- df[-1, ]

colnames(df)

# excluindo colunas desnecessarias
df2 <- df %>% select(-"SUB_DISTRICT_CODE", -"DISTRICT_CODE", -"REF_DATE")

colnames(df2)

# Renomeando várias colunas
df2 <- df2 %>% rename(
  region = NUTS,
  year = REF_YEAR,
  sex = SEX,
  country = ISO_ALP3,
  number = NUMBER)

#
unique(df_latam$year)

#
str(df_latam)

# Converter a coluna para numérico
df_latam$number <- as.numeric(df_latam$number)
str(df_latam)

#
df2 <- df2 %>%
  mutate(sex = case_when(
    sex == 1 ~ "MALE",
    sex == 2 ~ "FEMALE"
  ))

############################

# Lista de códigos Alpha-3 dos países da América Latina
latam_code <- c("ARG", "BOL", "BRA", "CHL", "COL", "CRI", 
                   "CUB", "ECU", "SLV", "GTM", "HTI", "HND", 
                   "MEX", "NIC", "PAN", "PRY", "PER", "DOM", 
                   "URY", "VEN")

# Filtrar o dataframe para incluir apenas os países da América Latina
df_latam <- df2 %>%
  filter(country %in% latam_code)

############################

# calcular o total de pessoas por pais 
total_country <- df_latam %>%
  group_by(country) %>%
  summarize(total_number = sum(number, na.rm = TRUE))

# calcular o total de homens e mulheres por pais
total_gender <- df_latam %>%
  group_by(country, sex) %>%
  summarize(total_number = sum(number, na.rm = TRUE), .groups = "drop")

# calcular o total de pessoas por pais e por ano
total_year <- df_latam %>%
  group_by(country, year) %>%
  summarize(total_number = sum(number, na.rm = TRUE), .groups = "drop")

# Calcular a porcentagem para o top10 países
top10_country <- total_country %>%
  slice_max(total_number, n = 10) %>%  # Seleciona os 10 países com maior população
  mutate(percentage = total_number / sum(total_number) * 100)  # Calcula a porcentagem

############################

# graficos 

# Gráfico de Barras Agrupadas total de homens e mulheres por pais
ggplot(total_gender %>% 
         group_by(country) %>% 
         summarise(number = sum(total_number)) %>% 
         slice_max(number, n = 10) %>%  # Filtra os 10 países com maior número de pessoas
         left_join(total_gender, by = "country"),  # Retorna o dataframe original após o filtro
       aes(x = reorder(country, -number, FUN = sum), y = total_number, fill = sex)) +
  
  geom_bar(stat = "identity", position = "dodge", width = 0.7, color = "black") +
  
  geom_label(aes(label = number_format(scale = 1e-3, accuracy = 0.1, suffix = "k")(total_number), 
                 group = sex),  # Assegura que o rótulo seja associado ao grupo correto
             position = position_dodge(width = 0.7),  # Manter o position_dodge para alinhar com as barras
             fill = "white", size = 3.5, hjust = 0.5, vjust = -0.5) +  # Ajustar vjust para posicionar acima da barra
  
  labs(title = "Population per Country and Sex through Years (2002 - 2024)", x = "Country", y = "Population") +
  scale_y_continuous(labels = label_number(scale = 1e-3, accuracy = 1, suffix = "k")) +  # Converte para 'k' e mantém 1 casa decimal
  
  scale_fill_viridis_d(option = "viridis", direction = -1) +  # Usando a paleta de cores Viridis invertida
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 9))  # Ajustar rótulos no eixo x
  
ggplotly() # make interactive plots


total_year$year <- as.numeric(as.character(total_year$year))


# Gráfico de linha para Total de Pessoas por País e Ano
ggplot(total_year, aes(x = as.numeric(year), y = total_number, 
                       color = reorder(country, -total_number), 
                       group = country)) +
  geom_line(size = 1) +
  # Only show points every 4 years
  geom_point(data = total_year %>% filter(year %in% c(2002, 2006, 2010, 2014, 2018, 2022)), 
             size = 1.5, alpha = 0.7) +

  geom_text_repel(data = total_year %>% filter(year == 2024),
                  aes(label = country), 
                  nudge_x = 0.3, size = 3, family = "roboto", color = "black", show.legend = FALSE) +
  
  geom_text_repel(data = total_year %>% filter(year == 2023, country == "BRA"),
                  aes(label = paste0(round(total_number, 0))),
                  nudge_x = 0.3, size = 3, family = "roboto", color = "black", show.legend = FALSE) +
  
  geom_text_repel(data = total_year %>% filter(year == 2013, country == "BRA"),
                  aes(label = paste0(round(total_number, 0))),
                  nudge_x = 0.3, size = 3, family = "roboto", color = "black", show.legend = FALSE) +
  
  geom_text_repel(data = total_year %>% filter(year == 2002, country == "BRA"),
                  aes(label = paste0(round(total_number, 0))),
                  nudge_x = 0.3, size = 3, family = "roboto", color = "black", show.legend = FALSE) +
  
  labs(title = "Population per Country through Years (2002 - 2024)", 
       x = "Year", 
       y = "Population", 
       color = "Country") +
  
  scale_color_viridis_d(option = "viridis", direction = -1) +
  
  scale_x_continuous(breaks = seq(2002, 2024, by = 4)) +  # Show every 4 years
  
  theme_minimal() +
  theme(legend.position = "none", 
        text = element_text(family = "roboto"),
        plot.title = element_text(size = 14, face = "bold", family = "roboto"),
        legend.text = element_text(size = 10, family = "roboto"))


# pie chart para analisar o total_country
ggplot(total_country %>% filter(country %in% (total_country %>% 
                                                slice_max(total_number, n = 10) %>% 
                                                pull(country))),
       aes(x = "", y = percentage, fill = reorder(country, -percentage))) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +  # Transforma o gráfico de barras em gráfico de pizza
  labs(title = "Population Percentage per LATAM Country - top10", 
       fill = "LATAM Country") +
  
  theme_void() +  # Remove o fundo e as linhas do gráfico
  theme(legend.position = "right", 
        text = element_text(family = "roboto"),  # Usando a fonte Roboto
        plot.title = element_text(size = 14, face = "bold", family = "roboto"),  
        legend.text = element_text(size = 10, family = "roboto")) +
  scale_fill_viridis_d(option = "viridis", direction = -1) +  # Paleta de cores Viridis
  
  geom_label(aes(label = paste0(country, ": ", round(percentage, 1), "%")), 
             position = position_stack(vjust = 0.5),  # Centraliza os rótulos
             size = 4,  # Ajusta o tamanho do texto
             label.size = 0.8,  # Tamanho da borda do rótulo
             color = "white", # Cor do texto
             show.legend = FALSE)  # Remove rótulos da legenda)  # Cor do texto





