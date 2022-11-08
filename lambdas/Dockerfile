FROM public.ecr.aws/lambda/python:3.9

RUN yum update -y

COPY hello_world.py .

CMD ["hello_world.lambda_handler"]
