# syntax=docker/dockerfile:latest

FROM rocker/shiny:4.2.0

RUN R -e "install.packages('renv')"

WORKDIR /srv/shiny-server/app

COPY renv.lock renv.lock
RUN mkdir -p renv
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.dcf renv/settings.dcf
ENV RENV_CONFIG_REPOS_OVERRIDE https://packagemanager.rstudio.com/cran/latest
RUN sudo apt-get update
RUN sudo apt-get install -y libssl-dev
RUN R -e 'if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")'
RUN R -e 'remotes::install_github("mdneuzerling/getsysreqs", force=TRUE)'
RUN REQS=$(Rscript -e 'options(warn = -1); cat(getsysreqs::get_sysreqs("renv.lock"))' | sed s/"WARNING: ignoring environment value of R_HOME"//) \
    && echo $REQS && sudo apt-get install -y $REQS

RUN chown -R shiny:shiny /srv/shiny-server

USER shiny

RUN R -e "renv::restore()"

# Copy all except folders and files starting with renv
COPY [^renv]* /srv/shiny-server/app/
