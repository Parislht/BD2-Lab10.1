import pandas as pd
import random
import math
import heapq
import os
import matplotlib.pyplot as plt


#Configuracion general

DATASET_PATH = r"C:\Users\Paris Herrera\Desktop\utec\2026 - 1\BD2\Semana11\DryBeanDataset\Dry_Bean_Dataset.xlsx"

SEED = 42
N_RANDOM_PAIRS = 5000

QUERY_IDS = [15, 2166, 4768]

RADIUS_PERCENTILES = [0.5, 1, 2, 5, 10]

K_VALUES = [2, 4, 8, 16, 32]

# Para carga y normalización
def load_dataset(path):
    df = pd.read_excel(path)

    label_column = "Class"
    feature_columns = [col for col in df.columns if col != label_column]

    return df, feature_columns, label_column

def normalize_zscore(df, feature_columns):
    normalized = df.copy()

    for col in feature_columns:
        mean = normalized[col].mean()
        std = normalized[col].std(ddof=0)

        if std == 0:
            
            normalized[col] = 0.0
        else:
            normalized[col] = (normalized[col] - mean) / std

    return normalized

def dataframe_to_vectors(df, feature_columns):
    vectors = []

    for _, row in df.iterrows():
        vector = []
        for col in feature_columns:
            vector.append(float(row[col]))
        vectors.append(vector)

    return vectors


# Distancia Euclidiana 
def euclidean_distance(vector_a, vector_b):
    total = 0.0

    for i in range(len(vector_a)):
        diff = vector_a[i] - vector_b[i]
        total += diff * diff

    return math.sqrt(total)


# Análisis de distribución de distancias
def percentile(sorted_values, p):
    if not sorted_values:
        return None

    index = int((p / 100.0) * (len(sorted_values) - 1))
    return sorted_values[index]

def analyze_distance_distribution(vectors, n_pairs=5000, seed=42):
    random.seed(seed)

    n = len(vectors)
    distances = []

    for _ in range(n_pairs):
        i = random.randint(0, n - 1)
        j = random.randint(0, n - 2)

        # Garantizamos que j sea diferente de i
        if j >= i:
            j += 1

        d = euclidean_distance(vectors[i], vectors[j])
        distances.append(d)

    distances.sort()

    mean_distance = sum(distances) / len(distances)

    variance = 0.0
    for d in distances:
        variance += (d - mean_distance) ** 2
    variance /= len(distances)

    std_distance = math.sqrt(variance)

    print("\n============================================================")
    print("ANALISIS DE DISTRIBUCIÓN DE DISTANCIAS - semilla fija 42")
    print("============================================================")
    print(f"N pares aleatorios: {n_pairs}")
    print(f"Distancia mínima: {distances[0]:.6f}")
    print(f"Distancia máxima: {distances[-1]:.6f}")


    print("\nPercentiles principales:")
    for p in [0.5, 1, 2, 5, 10]:
        print(f"Percentil {p:>5}%: {percentile(distances, p):.6f}")

    suggested_radii = []
    for p in RADIUS_PERCENTILES:
        suggested_radii.append(percentile(distances, p))

    print("\nRadios sugeridos para búsqueda por rango:")
    for i, r in enumerate(suggested_radii, start=1):
        print(f"r{i} = {r:.6f}    # percentil {RADIUS_PERCENTILES[i - 1]}%")

    return distances, suggested_radii



# Busqueda por rango
def range_search(vectors, labels, query_index, radius):
    query_vector = vectors[query_index]

    results = []

    for idx in range(len(vectors)):
        if idx == query_index:
            continue

        d = euclidean_distance(query_vector, vectors[idx])

        if d <= radius:
            results.append({
                "index": idx,
                "distance": d,
                "class": labels[idx]
            })

    # Ordenamos por distancia 
    results.sort(key=lambda item: item["distance"])

    return results

def calculate_precision(results, query_class):

    if len(results) == 0:
        return None

    relevant = 0

    for item in results:
        if item["class"] == query_class:
            relevant += 1

    return relevant / len(results)

# Ejecución de las 15 busquedas 
def run_range_experiments(df, vectors, labels, radii, query_ids):

    print("\n============================================================")
    print("BUSQUEDA POR RANGO")
    print("============================================================")

    precision_table = {}

    for r_idx, radius in enumerate(radii, start=1):
        row_key = f"r{r_idx} = {radius:.6f}"
        precision_table[row_key] = {}

        print(f"\n------------------------------------------------------------")
        print(f"{row_key}")
        print("------------------------------------------------------------")

        for q_id in query_ids:
            
            query_index = q_id - 1

            query_class = labels[query_index]

            results = range_search(
                vectors=vectors,
                labels=labels,
                query_index=query_index,
                radius=radius
            )

            precision = calculate_precision(results, query_class)

            if precision is None:
                precision_text = "N/A"
                precision_table[row_key][f"Q_{q_id}"] = "N/A"
            else:
                precision_text = f"{precision:.4f}"
                precision_table[row_key][f"Q_{q_id}"] = precision

            relevant_count = 0
            for item in results:
                if item["class"] == query_class:
                    relevant_count += 1

            print(f"Consulta Q_{q_id} \n")
            print(f"  Índice pandas usado: {query_index}")
            print(f"  Clase de la consulta: {query_class}")
            print(f"  Objetos recuperados: {len(results)}")
            print(f"  Objetos relevantes recuperados: {relevant_count}")
            print(f"  Precisión: {precision_text}\n\n")

    print("\n============================================================")
    print("TABLA FINAL DE PRECISION")
    print("============================================================")

    header = "Radio".ljust(20)
    for q_id in query_ids:
        header += f"Q_{q_id}".rjust(15)
    print(header)

    for row_key, values in precision_table.items():
        line = row_key.ljust(20)

        for q_id in query_ids:
            value = values[f"Q_{q_id}"]

            if value == "N/A":
                line += "N/A".rjust(15)
            else:
                line += f"{value:.4f}".rjust(15)

        print(line)

    return precision_table


#Busqueda de K vecinos mas cercano, con distancias negativas
def knn_search(vectors, labels, query_index, k):
    query_vector = vectors[query_index]

    # Heap de tamaño maximo k, como se vio en ADA jajaja
    # Se manejan las distancias negativas
    max_heap = []

    for idx in range(len(vectors)):
        if idx == query_index:
            continue

        d = euclidean_distance(query_vector, vectors[idx])

        if len(max_heap) < k:
            heapq.heappush(max_heap, (-d, idx, labels[idx]))
        else:
            worst_distance = -max_heap[0][0]

            if d < worst_distance:
                heapq.heapreplace(max_heap, (-d, idx, labels[idx]))

    results = []

    for negative_distance, idx, class_label in max_heap:
        results.append({
            "index": idx,
            "distance": -negative_distance,
            "class": class_label
        })

    results.sort(key=lambda item: item["distance"])

    return results

# Ejecución de P2 - 15 búsquedas KNN
def run_knn_experiments(df, vectors, labels, query_ids, k_values):
   
    print("\n============================================================")
    print("P2 - BUSQUEDA KNN")
    print("============================================================")

    precision_table = {}

    for k in k_values:
        row_key = f"k = {k}"
        precision_table[row_key] = {}

        print("\n------------------------------------------------------------")
        print(row_key)
        print("------------------------------------------------------------")

        for q_id in query_ids:
            query_index = q_id - 1
            query_class = labels[query_index]

            results = knn_search(
                vectors=vectors,
                labels=labels,
                query_index=query_index,
                k=k
            )

            precision = calculate_precision(results, query_class)
            precision_table[row_key][f"Q_{q_id}"] = precision

            relevant_count = 0
            for item in results:
                if item["class"] == query_class:
                    relevant_count += 1

            print(f"Consulta Q_{q_id}")
            print(f"  Índice pandas usado: {query_index}")
            print(f"  Clase de la consulta: {query_class}")
            print(f"  Vecinos recuperados: {len(results)}")
            print(f"  Objetos relevantes recuperados: {relevant_count}")
            print(f"  Precisión: {precision:.4f}")

            print("  Vecinos encontrados:")
            for rank, item in enumerate(results, start=1):
                print(
                    f"    {rank}. índice={item['index']}, "
                    f"distancia={item['distance']:.6f}, "
                    f"clase={item['class']}"
                )
                
            print()

    print("\n============================================================")
    print("TABLA FINAL DE PRECISION - KNN")
    print("============================================================")

    header = "K".ljust(12)
    for q_id in query_ids:
        header += f"Q_{q_id}".rjust(15)
    print(header)

    for row_key, values in precision_table.items():
        line = row_key.ljust(12)

        for q_id in query_ids:
            value = values[f"Q_{q_id}"]
            line += f"{value:.4f}".rjust(15)

        print(line)

    return precision_table



def main():
    df, feature_columns, label_column = load_dataset(DATASET_PATH)

    print("============================================================")
    print("DATASET CARGADO")
    print("============================================================")
    print(f"Filas: {df.shape[0]}")
    print(f"Columnas: {df.shape[1]}")

    normalized_df = normalize_zscore(df, feature_columns)

    vectors = dataframe_to_vectors(normalized_df, feature_columns)
    labels = df[label_column].tolist()

    # P1
    _, suggested_radii = analyze_distance_distribution(
        vectors=vectors,
        n_pairs=N_RANDOM_PAIRS,
        seed=SEED
    )

    run_range_experiments(
        df=df,
        vectors=vectors,
        labels=labels,
        radii=suggested_radii,
        query_ids=QUERY_IDS
    )

    # P2
    run_knn_experiments(
        df=df,
        vectors=vectors,
        labels=labels,
        query_ids=QUERY_IDS,
        k_values=K_VALUES
    )


def export_normalized_dataset_to_csv(
    input_path=DATASET_PATH,
    output_path=r"C:\Users\Paris Herrera\Desktop\utec\2026 - 1\BD2\Semana11\dry_beans_normalized.csv"
):
    
    df, feature_columns, label_column = load_dataset(input_path)

    normalized_df = normalize_zscore(df, feature_columns)

    export_df = pd.DataFrame()
    export_df["id_original"] = range(1, len(df) + 1)
    export_df["class"] = df[label_column]

    for i, col in enumerate(feature_columns, start=1):
        export_df[f"f{i}"] = normalized_df[col]

    export_df.to_csv(output_path, index=False, encoding="utf-8")

    print("\n============================================================")
    print("CSV EXPORTADO PARA POSTGRESQL")
    print("============================================================")
    print(f"Archivo generado: {output_path}")
    print(f"Filas exportadas: {export_df.shape[0]}")
    print(f"Columnas exportadas: {export_df.shape[1]}")
    print("\nPrimeras filas:")
    print(export_df.head())

    return output_path

def plot_knn_replicated_data():
    k_values = [2, 4, 8, 16, 32]

    sin_indice = [5.421, 5.955, 5.692, 5.676, 5.462]
    con_indice = [5.862, 5.382, 5.411, 5.654, 5.546]

    plt.figure(figsize=(8, 5))

    plt.plot(k_values, sin_indice, marker='o', label='Sin índice')
    plt.plot(k_values, con_indice, marker='o', label='Con índice GiST')

    plt.title('Tiempo de búsqueda KNN - Datos replicados')
    plt.xlabel('K')
    plt.ylabel('Tiempo de ejecución (ms)')
    plt.xticks(k_values)
    plt.grid(True)
    plt.legend()

    plt.tight_layout()
    plt.show()


def plot_knn_normal_data():
    k_values = [2, 4, 8, 16, 32]

    sin_indice = [4.810, 4.758, 4.760, 4.304, 4.399]
    con_indice = [4.035, 4.121, 4.230, 4.024, 4.019]

    plt.figure(figsize=(8, 5))

    plt.plot(k_values, sin_indice, marker='o', label='Sin índice')
    plt.plot(k_values, con_indice, marker='o', label='Con índice GiST')

    plt.title('Tiempo de búsqueda KNN - Datos normales')
    plt.xlabel('K')
    plt.ylabel('Tiempo de ejecución (ms)')
    plt.xticks(k_values)
    plt.grid(True)
    plt.legend()

    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()

    export_normalized_dataset_to_csv()

    plot_knn_normal_data()
    
    plot_knn_replicated_data()

   