FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine

ENV DOTNET_CLI_TELEMETRY_OPTOUT true
ENV DOTNET_NOLOGO true

# Install .NET 6.0 for runtime compatibility
COPY --from=mcr.microsoft.com/dotnet/sdk:6.0-alpine /usr/share/dotnet/shared /usr/share/dotnet/shared

# Install .NET 7.0 for runtime compatibility
COPY --from=mcr.microsoft.com/dotnet/sdk:7.0-alpine /usr/share/dotnet/shared /usr/share/dotnet/shared

RUN apk --update --no-cache add nodejs npm jq curl bash git && \
    npm install -g aws-cdk

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/altavec/dotnet-cdk-action"