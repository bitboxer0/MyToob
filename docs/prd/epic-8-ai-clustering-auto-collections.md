# Epic 8: AI Clustering & Auto-Collections

**Goal:** Implement graph-based clustering using kNN graph construction and Leiden/Louvain community detection algorithms to automatically group related videos by topic. Generate human-readable labels for each cluster using keyword extraction. This epic enables the "smart collections" feature that helps users discover thematic connections in their video library.

## Story 8.1: kNN Graph Construction from Embeddings

As a **developer**,
I want **a k-nearest-neighbors graph built from all video embeddings**,
so that **similar videos are connected and can be clustered**.

**Acceptance Criteria:**
1. For each video embedding, find k=10 nearest neighbors using HNSW index
2. Construct undirected graph: nodes = videos, edges = k-nearest-neighbor connections
3. Edge weights = cosine similarity between embeddings (higher weight = more similar)
4. Graph stored in memory (adjacency list representation)
5. Graph construction time measured: <2 seconds for 1,000 videos on M1 Mac
6. Graph updated incrementally when new videos added (add new node + edges, no full rebuild)
7. Unit tests verify graph structure (degree distribution, connectivity)

## Story 8.2: Leiden Community Detection Algorithm

As a **developer**,
I want **Leiden algorithm applied to kNN graph to detect topic clusters**,
so that **videos are grouped by semantic similarity**.

**Acceptance Criteria:**
1. Leiden algorithm implemented (or integrated from existing Swift/C++ library)
2. Algorithm runs on kNN graph to detect communities (clusters)
3. Leiden parameters tuned: resolution=1.0 (controls cluster granularity)
4. Output: assignment of each video to a cluster ID (e.g., video A → cluster 3)
5. Cluster count reasonable: typically 5-20 clusters for 1,000 videos (not too many, not too few)
6. Clustering time measured: <3 seconds for 1,000-video graph on M1 Mac
7. Re-clustering triggered when library grows significantly (e.g., +100 videos)
8. Unit tests verify algorithm produces non-trivial clustering (not all videos in one cluster)

## Story 8.3: Cluster Centroid Computation & Label Generation

As a **developer**,
I want **each cluster to have a human-readable label generated from member video titles**,
so that **users understand what each auto-collection represents**.

**Acceptance Criteria:**
1. For each cluster, compute centroid: average of all member video embeddings
2. Extract keywords from member video titles using TF-IDF or frequency analysis
3. Select top 3-5 keywords as cluster label (e.g., "Swift, Concurrency, Async")
4. Label formatted: "Swift Concurrency" (title case, comma-separated keywords)
5. Labels stored in `ClusterLabel` model with `clusterID`, `label`, `centroid`, `itemCount`
6. Labels unique (no duplicate labels across clusters—append disambiguation if needed)
7. "Rename Cluster" action allows user to override auto-generated label
8. UI test verifies cluster labels are generated correctly for sample data

## Story 8.4: Auto-Collections UI in Sidebar

As a **user**,
I want **to see auto-generated topic collections in the sidebar**,
so that **I can browse videos grouped by AI-detected themes**.

**Acceptance Criteria:**
1. Sidebar section added: "Smart Collections" (above or below manual collections)
2. Each `ClusterLabel` displayed as a sidebar item: label + count (e.g., "Swift Concurrency (24)")
3. Clicking cluster loads videos in that cluster in main content area
4. Cluster icon: system icon indicating AI-generated (e.g., sparkles icon)
5. Clusters sorted by size (largest first) or alphabetically (user preference in Settings)
6. Empty clusters (0 videos) not shown in sidebar
7. "Hide Smart Collections" toggle in Settings for users who prefer manual organization only

## Story 8.5: Cluster Stability & Re-Clustering Trigger

As a **developer**,
I want **clustering to remain stable across app restarts and only re-cluster when necessary**,
so that **users don't see collections constantly changing**.

**Acceptance Criteria:**
1. Cluster assignments persisted in SwiftData (add `clusterID` property to `VideoItem`)
2. On app launch, load existing clusters from SwiftData (no re-clustering unless needed)
3. Re-clustering triggered when: user manually requests, library grows by >10% since last clustering, AI model updated
4. Re-clustering runs in background (doesn't block UI)
5. After re-clustering, old cluster IDs mapped to new clusters to preserve user edits (e.g., renamed labels)
6. "Re-cluster Now" action in Settings forces full re-clustering
7. Cluster stability measured: >90% of videos remain in same cluster after re-clustering (goal: minimize churn)

## Story 8.6: Cluster Detail View & Refinement

As a **user**,
I want **to view all videos in a cluster and refine the cluster**,
so that **I can understand and improve auto-generated collections**.

**Acceptance Criteria:**
1. Clicking cluster in sidebar loads cluster detail view
2. Detail view shows: cluster label, video count, member videos in grid/list
3. "Rename Cluster" button allows custom label (overrides auto-generated)
4. "Merge with..." action combines two clusters into one (user selects second cluster)
5. "Remove from Cluster" action on individual videos (moves video out of cluster)
6. "Convert to Manual Collection" creates a user collection from cluster (preserves videos, removes from smart collections)
7. Changes to clusters persist across app restarts

---
