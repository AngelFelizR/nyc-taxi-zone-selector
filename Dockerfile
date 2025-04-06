FROM rocker/r-ver:4.4.2
RUN /rocker_scripts/install_geospatial.sh
LABEL maintainer="Angel Feliz" description="NYC Taxi Shiny application"

# Moving all files to correct folder
# But excluding the renv
WORKDIR /code
COPY . .
RUN rm -rf renv/

# using approach 2 above
RUN mkdir renv
COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# Solving problems with cache
ENV HOME=/code
RUN mkdir -p /code/.cache/R

# restore
RUN R -e "renv::restore()"
RUN R -e "install.packages('tibble')"
