FROM rocker/geospatial:4.4.2
LABEL maintainer="Angel Feliz" description="NYC Taxi Shiny application"
WORKDIR /code
COPY . .
RUN rm -rf renv/
COPY renv.lock renv.lock
RUN mkdir -p renv
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json
RUN R -e "renv::restore()"
RUN R -e "install.packages('tibble')"
CMD ["R", "--quiet", "-e", "shiny::runApp(host='0.0.0.0', port=7860)"]
EXPOSE 7860


