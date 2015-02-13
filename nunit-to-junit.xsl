<?xml version="1.0" encoding="UTF-8"?>
<!--
# Author: Michael Goff <Michael.Goff@Quantum.com>
# Licence: MIT
# Copyright (c) 2015, Quantum Corp.
# Description:
# Convert nunit output to junit format
# Based loosely off https://github.com/jenkinsci/nunit-plugin/blob/master/src/main/resources/hudson/plugins/nunit/nunit-to-junit.xsl
-->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" indent="yes" />

	<xsl:template match="/test-results">
		<testsuites>
			<xsl:for-each select="//test-suite[@type='Namespace' or @type='SetUpFixture']/results/test-suite[@type='TestFixture'][1]">
				<xsl:variable name="suitename">
					<xsl:for-each select="ancestor::test-suite[@type='Namespace' or (@type='SetUpFixture' and not(parent::test-results))]">
						<xsl:choose>
							<xsl:when test="position() = 1"><xsl:value-of select="@name"/></xsl:when>
							<xsl:otherwise>.<xsl:value-of select="@name"/></xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>

				<xsl:variable name="testcases" select="../test-suite[@type='TestFixture']//test-case" />

				<testsuite name="{$suitename}"
					tests="{count($testcases)}" time="{@time}"
					failures="{count($testcases[@result='Failure'])}" errors="{count($testcases[@result='Error'])}"
					skipped="{count($testcases[@executed='False']) + count($testcases[@result='Inconclusive'])}">
					<xsl:for-each select="$testcases">
						<xsl:variable name="classname" select="ancestor::test-suite[@type='TestFixture']/@name" />
						<xsl:variable name="testname" select="substring-after(@name, concat(concat($suitename, concat('.', $classname)), '.'))" />
						<testcase classname="{$classname}" name="{$testname}">
							<xsl:if test="@time!=''">
							   <xsl:attribute name="time"><xsl:value-of select="@time" /></xsl:attribute>
							</xsl:if>

							<xsl:if test="@result='Failure'">
								<failure>
MESSAGE:
<xsl:value-of select="./failure/message" />
+++++++++++++++++++
STACK TRACE:
<xsl:value-of select="./failure/stack-trace" />
								</failure>
							</xsl:if>
							<xsl:if test="@result='Error'">
								<error type="{substring-before(./failure/message,' :')}">
MESSAGE:
<xsl:value-of select="./failure/message" />
+++++++++++++++++++
STACK TRACE:
<xsl:value-of select="./failure/stack-trace" />
								</error>
							</xsl:if>
							<xsl:if test="@executed='False'">
								<skipped>
									<xsl:attribute name="message"><xsl:value-of select="./reason/message"/></xsl:attribute>
								</skipped>
							</xsl:if>
							<xsl:if test="@result='Inconclusive'">
								<skipped message="Inconclusive"></skipped>
							</xsl:if>
						</testcase>
					</xsl:for-each>
				</testsuite>
			</xsl:for-each>
		</testsuites>
	</xsl:template>
</xsl:stylesheet>
