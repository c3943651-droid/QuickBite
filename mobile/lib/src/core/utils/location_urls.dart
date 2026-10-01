/// URIs para abrir una ubicación en apps externas de navegación (07.5 §3.10).
Uri googleMapsUri(double latitud, double longitud) => Uri.parse(
  'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud',
);

Uri wazeUri(double latitud, double longitud) =>
    Uri.parse('https://waze.com/ul?ll=$latitud,$longitud');
