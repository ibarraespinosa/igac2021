library(stars)
library(eixport)
library(raster)
library(sf)
library(cptcity)
reg <- st_read("../../papers/IBARRA/2021_Ibarra_Santos/shapefiles/regiones.shp")
# reg <- st_cast(reg, "LINESTRING")
cl <- st_read("../../papers/IBARRA/2021_Ibarra_Santos/shapefiles/ne_50m_coastline.shp")
doms <- readRDS("oral/doms.rds")
d1 <- doms[2, ]
doms <- st_cast(doms, "LINESTRING")
cl <- st_crop(cl, d1)
cl <- st_transform(cl, 4326)

rx <- st_cast(reg, "MULTILINESTRING")

e1 <- eixport::wrf_get(
  file= "/media/sergio/My Passport1/inventarios/masp2014/wrfchemi_00z_d02",
  name = "E_NO",
  as_raster = T)
e2 <- eixport::wrf_get(
  file= "/media/sergio/My Passport1/inventarios/masp2014/wrfchemi_12z_d02",
  name = "E_NO",
  as_raster = T)
e <- brick(list(e1, e2))
e <- st_as_stars(e)
e$E_NO_2014.10.03_00.00.00 <- ifelse(as.numeric(e$E_NO_2014.10.03_00.00.00) <= 0,
                                     NA,
                                     e$E_NO_2014.10.03_00.00.00)
e <- adrop(e)
st_crs(e) <- 4326
nb<- classInt::classIntervals(
  var = as.numeric(e$E_NO_2014.10.03_00.00.00),
  n = 100,
  style = "quantile")

dir.create("figemis")
horas <- c(paste0("0", 0:9), 10:23)
lapply(c(22:24, 1:21), function(i) {
  png(paste0("figemis/", horas[i], ".png"), width = 1000, height = 1000, res = 100)
  plot(e[,,,i],
       col = cpt(3465, n = length(nb$brks) - 1),
       reset = F,
       axes = T,
       main = paste0("NO ",i-1, ":00 [mol/km²/h]"),
       breaks = nb$brks,
       bg = "black")
  # plot(cl$geometry, add = T)
  plot(rx, add = T)
dev.off()
})

library(magick)
list.files("figemis/", full.names = T) -> fi
lapply(fi, image_read) -> fli
image_animate(image = do.call("c", fli)) -> ani
image_write(image = ani, path = "oral/ani.gif")
