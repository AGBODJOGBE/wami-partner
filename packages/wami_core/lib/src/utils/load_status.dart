/// État de chargement générique d'une donnée dans un bloc.
enum LoadStatus {
  idle,
  loading,
  ready,
  failure;

  bool get isLoading => this == loading;
  bool get isReady => this == ready;
}
