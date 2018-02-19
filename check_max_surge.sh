while true; do
  for i in $(kubectl get pods -l app=hello-k8s -o template --template="{{range .items}} {{range .spec.containers}} {{ .image}} {{end}} {{.status.phase }} {{end}}"); do
    echo "$i"
  done
  sleep 5
  clear
done