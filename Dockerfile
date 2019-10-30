FROM sonarqube:7.7-community

USER root

ADD sonar.properties /opt/sonarqube/conf/sonar.properties
ADD run.sh /opt/sonarqube/bin/run.sh
CMD /opt/sonarqube/bin/run.sh
RUN cp -a /opt/sonarqube/data /opt/sonarqube/data-init && \
	cp -a /opt/sonarqube/extensions /opt/sonarqube/extensions-init && \
	chown sonarqube:sonarqube /opt/sonarqube && chmod -R gu+rwX /opt/sonarqube
ADD plugins.sh /opt/sonarqube/bin/plugins.sh
#RUN /opt/sonarqube/bin/plugins.sh pmd gitlab github ldap
RUN /opt/sonarqube/bin/plugins.sh pmd gitlab github
RUN chmod -R 777 /opt/sonarqube

USER sonarqube