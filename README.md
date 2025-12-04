# 🌾 SeedTech: Sistema de Monitoramento de Armazéns Inteligentes

Um projeto de banco de dados relacional (MySQL) para monitorar e organizar dados de temperatura, umidade, luminosidade e distância (nível de estoque) coletados por dispositivos **ESP32** e diversos sensores instalados em armazéns.

---

## 🎯 Objetivo do Projeto (Minimundo)

O sistema **SeedTech** modela o ambiente de controle de armazéns que armazenam grãos e sementes. O objetivo é garantir a **preservação da qualidade** dos produtos agrícolas através do monitoramento contínuo das condições ambientais e do nível de estoque.

### O Minimundo

O sistema é baseado na relação entre **Armazéns** e **Dispositivos ESP32**.
* **Armazéns** possuem informações de nome, localização e capacidade.
* Cada armazém hospeda **pelo menos um** Dispositivo ESP32.
* O **Dispositivo ESP32** é o controlador central no armazém, responsável por gerenciar e registrar dados de **três tipos de sensores**:
    1.  **DHT22 (Temperatura e Umidade):** Para monitorar as condições climáticas internas.
    2.  **LDR (Luminosidade):** Para medir a incidência de luz.
    3.  **Ultrassônico (Distância/Nível):** Para monitorar o nível do estoque de grãos.
* Cada tipo de sensor possui uma tabela de **Dados** correspondente para armazenar as leituras (timestamp, temperatura, distância, etc.) de forma histórica.

---

## ⚙️ Tecnologias e Dependências

Este projeto foi desenvolvido utilizando as seguintes tecnologias:

* **SGBD:** **MySQL**
* **Linguagem de Modelagem:** SQL
* **Ferramentas:** Cliente SQL (MySQL Workbench, DBeaver, etc.)

---

## 🗺️ Diagrama do Esquema (Modelo ER)

O diagrama abaixo ilustra todas as entidades (tabelas), seus atributos, e os relacionamentos definidos pelo projeto, incluindo as cardinalidades.

* ***Lembre-se de salvar seu diagrama com o nome `schema.png` dentro da pasta `docs/` no seu repositório.***

![Diagrama do Esquema Relacional](docs/schema.png)

---

## 🏗️ Estrutura do Banco de Dados (Entidades Chave)

O modelo é composto por 8 entidades principais, organizadas para garantir a integridade referencial dos dados:

| Entidade | Descrição |
| :--- | :--- |
| **Armazéns** | Informações sobre o local de armazenamento (Nome, Localização, Capacidade). |
| **ESP32_Dispositivos** | Dispositivos controladores que fazem a ponte entre o Armazém e os Sensores. |
| **DHT22_Sensores** | Sensores de Temperatura e Umidade. |
| **LDR_Sensores** | Sensores de Luminosidade. |
| **Ultrassonico_Sensores** | Sensores de Distância (para medição de nível de estoque). |
| **DHT22_Dados** | Armazena as leituras de Temperatura e Umidade. |
| **LDR_Dados** | Armazena as leituras de Luminosidade. |
| **Ultrassonico_Dados** | Armazena as leituras de Distância e Impacto (nível de estoque). |

---

## 🚀 Instalação e Configuração

Para configurar o banco de dados **SeedTech** localmente:

1.  **Pré-requisitos:** Certifique-se de ter o **MySQL Server** e um cliente SQL instalados.
2.  **Clone o Repositório:**
    ```bash
    git clone [https://github.com/seu-usuario/seedtech.git](https://github.com/seu-usuario/seedtech.git)
    cd seedtech
    ```
3.  **Crie o Banco de Dados:**
    Acesse seu cliente MySQL (ou terminal) e execute o comando:
    ```sql
    CREATE DATABASE seedtech_db;
    USE seedtech_db;
    ```
4.  **Execute o Script de Criação:**
    Execute o script SQL principal (ex: `schema_creation.sql`) para construir a estrutura do banco de dados.
    ```bash
    # Exemplo de execução via linha de comando
    mysql -u root -p seedtech_db < schema_creation.sql
    ```
5.  **Populando o BD (Opcional):**
    Se houver, execute o script de dados de exemplo (`sample_data.sql` ou similar).

---

## 🔍 Exemplos de Consultas Chave

A seguir, um exemplo de consulta avançada para extrair dados ambientais críticos do sistema, focada na temperatura média por armazém:

```sql
### Consulta: Temperatura Média por Armazém

-- Esta consulta retorna a temperatura média registrada por cada sensor DHT22 
-- em um armazém específico, permitindo a identificação de pontos quentes.

SELECT 
    arm.nome AS "Armazém",
    arm.localizacao AS "Localização do Armazém", 
    CONCAT('DHT22 ', dhts.id) AS "Sensor DHT22 ID", 
    dhts.localizacao_detalhada AS "Localização do Sensor",
    ROUND(AVG(dhtd.temperatura), 2) AS "Temperatura Média (°C)", 
    MAX(dhtd.timestamp) AS "Último Registro"
FROM 
    armazens arm 
INNER JOIN 
    esp32_dispositivos esp ON arm.id = esp.armazens_id 
INNER JOIN 
    dht22_sensores dhts ON esp.id = dhts.esp32_dispositivo_id 
INNER JOIN 
    dht22_dados dhtd ON dhts.id = dhtd.dht22_sensor_id 
GROUP BY 
    arm.nome, arm.localizacao, dhts.id, dhts.localizacao_detalhada
ORDER BY 
    "Temperatura Média (°C)" DESC;
